//
//  FileDownloader.swift
//  FileDownloader
//
//  Created by Yuta Kawabe on 2020/03/26.
//  Copyright © 2020 yuta kawabe. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

enum DownloadState: Equatable {
    case downloading(Float)
    case done(URL)
    case error(Error)
    
    static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.downloading(let progressL), .downloading(let progressR)):
            return progressL == progressR
        case (.done, .done):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

final class FileDownloader: NSObject {
    
    private var state = PublishSubject<DownloadState>()
    private var filename = ""
    private var task: URLSessionDownloadTask!
    
    func download(_ url: URL, name: String? = nil) -> Observable<DownloadState> {
        filename = name ?? url.lastPathComponent
        return Observable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            let disposable = self.state.bind(to: observer)
            self.startDownload(url)
            return disposable
        }
    }
    
    func cancel() {
        task.cancel()
    }
}

extension FileDownloader {
    
    private func startDownload(_ url: URL) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        let request = URLRequest(url: url)
        task = session.downloadTask(with: request)
        task.resume()
    }
}

extension FileDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        state.onNext(.done(location))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let current = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        state.onNext(.downloading(current))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            state.onNext(.error(error))
        }
    }
}
