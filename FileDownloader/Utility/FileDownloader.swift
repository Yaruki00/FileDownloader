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

/// ダウンロードの状態
enum DownloadState: Equatable {
    /// ダウンロード中(進捗)
    case downloading(Float)
    /// 完了(保存先URL)
    case done(URL)
    /// 失敗(エラー詳細)
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
    
    // ダウンロードの状態を流す用
    // 繰り返し使う想定なのでPublishRelayにして、ObservableでいうonErrorは使わないようにする
    private var state = PublishRelay<DownloadState>()
    private var filename = ""
    private var task: URLSessionDownloadTask!
    
    /// ダウンロード開始
    func download(_ url: URL, name: String? = nil) -> Observable<DownloadState> {
        filename = name ?? url.lastPathComponent
        return Observable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            // 関数呼び出されるたびにbindしてるけど大丈夫？教えてエラい人！
            let disposable = self.state.bind(to: observer)
            self.startDownload(url)
            return disposable
        }
    }
    
    /// ダウンロード中断
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
    
    // ダウンロードが完了した時に呼ばれる
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        state.accept(.done(location))
    }
    
    // ダウンロードの進捗が変化した時に呼ばれる
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let current = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        state.accept(.downloading(current))
    }
    
    // ダウンロードが失敗した時に呼ばれる
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            state.accept(.error(error))
        }
    }
}
