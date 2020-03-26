//
//  ViewController.swift
//  FileDownloader
//
//  Created by Yuta Kawabe on 2020/03/26.
//  Copyright © 2020 yuta kawabe. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var label: UILabel!
    
    private let fileDownloader = FileDownloader()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
}

extension ViewController {
    
    private func bind() {
        
        textField.rx.text
            .map { !($0?.isEmpty ?? true) }
            .bind(to: button.rx.isEnabled)
            .disposed(by: disposeBag)
        
        button.rx.tap
            .map { [weak self] _ -> URL? in
                let text = self?.textField.text ?? ""
                return URL(string: text)
            }
            .flatMap { $0.flatMap(Observable.just) ?? Observable.empty() }
            .flatMap { [weak self] url -> Observable<DownloadState> in
                return self?.fileDownloader.download(url) ?? .error(NSError(domain: "", code: 0, userInfo: nil))
            }
            .distinctUntilChanged()
            .map { state -> String in
                switch state {
                case .downloading(let progress):
                    return "downloading(\(String(format: "%.2f", progress * 100) + "%"))..."
                case .done(let url):
                    return "done!\n\(url.absoluteString)"
                case .error(let error):
                    return "error occurred\n\(error.localizedDescription)"
                }
            }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }
}
