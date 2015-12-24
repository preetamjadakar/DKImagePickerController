//
//  DKImageManager.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 15/11/29.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import Photos

public class DKBaseManager: NSObject {

	private let observers = NSHashTable.weakObjectsHashTable()
	
	public func addObserver(object: AnyObject) {
		self.observers.addObject(object)
	}
	
	public func removeObserver(object: AnyObject) {
		self.observers.removeObject(object)
	}
	
	public func notifyObserversWithSelector(selector: Selector, object: AnyObject?) {
		self.notifyObserversWithSelector(selector, object: object, objectTwo: nil)
	}
	
	public func notifyObserversWithSelector(selector: Selector, object: AnyObject?, objectTwo: AnyObject?) {
		if self.observers.count > 0 {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				for observer in self.observers.objectEnumerator() {
					if observer.respondsToSelector(selector) {
						observer.performSelector(selector, withObject: object, withObject: objectTwo)
					}
				}
			})
		}
	}

}

public func getImageManager() -> DKImageManager {
	return DKImageManager.sharedInstance
}

public class DKImageManager: DKBaseManager {
	
	public class func checkPhotoPermission(handler: (granted: Bool) -> Void) {
		func hasPhotoPermission() -> Bool {
			return PHPhotoLibrary.authorizationStatus() == .Authorized
		}
		
		func needsToRequestPhotoPermission() -> Bool {
			return PHPhotoLibrary.authorizationStatus() == .NotDetermined
		}
		
		hasPhotoPermission() ? handler(granted: true) : (needsToRequestPhotoPermission() ?
			PHPhotoLibrary.requestAuthorization({ status in
				dispatch_async(dispatch_get_main_queue(), { () in
					hasPhotoPermission() ? handler(granted: true) : handler(granted: false)
				})
			}) : handler(granted: false))
	}
	
	static let sharedInstance = DKImageManager()
	
	private let manager = PHCachingImageManager.defaultManager()
	
	private lazy var defaultImageRequestOptions: PHImageRequestOptions = {
		let options = PHImageRequestOptions()
		options.deliveryMode = .HighQualityFormat
		options.resizeMode = .Exact;
		
		return options
	}()
	
	public let groupDataManager = DKGroupDataManager()
	
	public func invalidate() {
		self.groupDataManager.invalidate()
	}
	
	public func fetchImageForAsset(asset: DKAsset, size: CGSize, completeBlock: (image: UIImage?) -> Void) {
		self.fetchImageForAsset(asset, size: size, options: self.defaultImageRequestOptions, completeBlock: completeBlock)
	}
	
	public func fetchImageForAsset(asset: DKAsset, size: CGSize, options: PHImageRequestOptions, completeBlock: (image: UIImage?) -> Void) {
		self.manager.requestImageForAsset(asset.originalAsset!,
			targetSize: size,
			contentMode: .AspectFill,
			options: options,
			resultHandler: { image, info in
				completeBlock(image: image)
		})
	}
	
	public func fetchAVAsset(asset: DKAsset, completeBlock: (avAsset: AVURLAsset?) -> Void) {
		self.manager.requestAVAssetForVideo(asset.originalAsset!,
			options: nil) { (avAsset, audioMix, info) -> Void in
				completeBlock(avAsset: avAsset as? AVURLAsset)
		}
	}
	
}
