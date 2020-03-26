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
        
        // ボタンが押された
        button.rx.tap
            // テキストフィールドの文字列をURLに変換
            .map { [weak self] _ -> URL? in
                let text = self?.textField.text ?? ""
                return URL(string: text)
            }
            // オプショナルのアンラップ
            .flatMap { $0.flatMap(Observable.just) ?? Observable.empty() }
            // URLをもとにダウンロード
            .flatMap { [weak self] url -> Observable<DownloadState> in
                return self?.fileDownloader.download(url) ?? .error(NSError(domain: "", code: 0, userInfo: nil))
            }
            // 前回と同じ状態なら無視
            .distinctUntilChanged()
            // ダウンロードの状態をもとにラベルに表示する文字列生成
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
            // ラベルに流す
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }
}
