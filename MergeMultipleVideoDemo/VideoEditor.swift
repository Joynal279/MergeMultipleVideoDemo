//
//  VideoEditor.swift
//  MergeMultipleVideoDemo
//
//  Created by Joynal Abedin on 11/12/22.
//
import UIKit
import AVFoundation
import Photos

class VideoEditor {
    
    let mixComposition = AVMutableComposition()
    let mainComposition = AVMutableVideoComposition()
    let mainInstruction = AVMutableVideoCompositionInstruction()
    var allVideoInstruction = [AVMutableVideoCompositionLayerInstruction]()
    var startDuration: CMTime = .zero
    
    func makeVideoComposition(fromVideoAt videoAsset: [AVAsset], onComplete: @escaping (AVPlayerItem?) -> Void) {
        
        for i in 0..<videoAsset.count {
            let currentAsset = videoAsset[i]
            let assetTrack = currentAsset.tracks(withMediaType: .video)[0]
            let currentTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            do {
                try currentTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: currentAsset.duration), of: assetTrack, at: startDuration)
                let currentInstruction: AVMutableVideoCompositionLayerInstruction = compositionLayerInstruction(for: currentTrack!, assetTrack: assetTrack)
                allVideoInstruction.append(currentInstruction)
                startDuration = CMTimeAdd(startDuration, currentAsset.duration)
                
            } catch {
                print("❌ Error_Loading_ Video")
            }
            
            //******* Start Calculate Video Asset Size ***********//
            let videoTrack = mixComposition.tracks(withMediaType: .video)[0]
            let trackSize = videoTrack.naturalSize
            //set ration here
            //YouTube: 16:9 (max upload 4k – 3840 x 2160)
            //width: 16 and height: 9
            let rect = AVMakeRect(aspectRatio: CGSize(width: 1, height: 1), insideRect: CGRect(origin: .zero, size: CGSize(width: trackSize.width, height: trackSize.height)))
            
            //******* End Calculate Video Asset Size ***********//
            
            mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: startDuration)
            mainInstruction.layerInstructions = allVideoInstruction
            
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            mainComposition.renderSize = rect.size
            
            //exportVideo
            exportVideo(mixComposition: mixComposition, mainComposition: mainComposition)
            
            ///Prepare playerView
            let item = AVPlayerItem(asset: self.mixComposition)
            //item.audioMix = self.mix
            item.videoComposition = self.mainComposition
            
            onComplete(item)
            
        }
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
    
    //Export final video
    func exportVideo(mixComposition composition: AVMutableComposition, mainComposition videoComposition: AVMutableVideoComposition) {
        //export code here
        print("export pressed")
        //  create new file to receive data
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = dirPaths[0] as NSString
        let movieFilePath = docsDir.appendingPathComponent("result.mov")
        let movieDestinationUrl = NSURL(fileURLWithPath: movieFilePath)
        
        // use AVAssetExportSession to export video
        let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality)
        assetExport?.videoComposition = videoComposition
        //assetExport?.audioMix = mix
        assetExport?.outputFileType = AVFileType.mov
        
        // Check exist and remove old file
        FileManager.default.removeItemIfExisted(movieDestinationUrl as URL)
        
        assetExport?.outputURL = movieDestinationUrl as URL
        assetExport?.exportAsynchronously(completionHandler: {
            switch assetExport!.status {
            case AVAssetExportSession.Status.failed:
                print("failed")
                print(assetExport?.error ?? "unknown error")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled")
                print(assetExport?.error ?? "unknown error")
            default:
                print("Movie complete")
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieDestinationUrl as URL)
                }) { saved, error in
                    if saved {
                        print("Saved")
                    }
                }
                
            }
        })
    }
    
}

//check existing item
extension FileManager {
    func removeItemIfExisted(_ url:URL) -> Void {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            }
            catch {
                print("Failed to delete file")
            }
        }
    }
}
