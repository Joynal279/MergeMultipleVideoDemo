//
//  ViewController.swift
//  MergeMultipleVideoDemo
//
//  Created by Joynal Abedin on 11/12/22.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var editor = VideoEditor()
    var assetArray: [AVAsset] = [
                                AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "movie", ofType:"mov")!)),
                                 AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "pointFilm", ofType:"mp4")!))
                                ]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editor.makeVideoComposition(fromVideoAt: assetArray) { playerItem in
            print("Composition completed")
        }
    }


}

