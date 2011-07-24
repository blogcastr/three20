//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20UI/private/TTImageViewInternal.h"

// Core
#import "Three20Core/TTCorePreprocessorMacros.h"

// UI
#import "Three20UI/TTImageViewDelegate.h"
#import "Three20UI/UIViewAdditions.h"

// UI (private)
#import "Three20UI/private/TTImageLayer.h"


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
TT_FIX_CATEGORY_BUG(TTImageViewInternal)

static inline double radians (double degrees) {
  return degrees * M_PI/180;
}

@implementation TTImageView (TTInternal)


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateLayer {
  TTImageLayer* layer = (TTImageLayer*)self.layer;
  if (self.style) {
    layer.override = nil;

  } else {
    // This is dramatically faster than calling drawRect.  Since we don't have any styles
    // to draw in this case, we can take this shortcut.
    layer.override = self;
  }

  [layer setNeedsDisplay];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setImageRef:(UIImage*)image {
  CGImageRef imageRef;
  CGBitmapInfo bitmapInfo;
  CGColorSpaceRef colorSpaceInfo;
  CGContextRef bitmap;

  if (_imageRef)
    CGImageRelease(_imageRef);
  if (!image) {
    _imageRef = nil;
    return;
  }
  imageRef = image.CGImage;
  bitmapInfo = CGImageGetBitmapInfo(imageRef);
  colorSpaceInfo = CGImageGetColorSpace(imageRef);
  if (bitmapInfo == kCGImageAlphaNone)
    bitmapInfo = kCGImageAlphaNoneSkipLast;
  if (image.imageOrientation == UIImageOrientationUp || image.imageOrientation == UIImageOrientationDown)
    bitmap = CGBitmapContextCreate(NULL, image.size.width, image.size.height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
  else
    bitmap = CGBitmapContextCreate(NULL, image.size.height, image.size.width, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
  if (image.imageOrientation == UIImageOrientationLeft) {
    CGContextRotateCTM (bitmap, radians(90));
    CGContextTranslateCTM (bitmap, 0, -image.size.height);
  } else if (image.imageOrientation == UIImageOrientationRight) {
    CGContextRotateCTM (bitmap, radians(-90));
    CGContextTranslateCTM (bitmap, -image.size.width, 0);
  } else if (image.imageOrientation == UIImageOrientationDown) {
    CGContextTranslateCTM (bitmap, image.size.width, image.size.height);
    CGContextRotateCTM (bitmap, radians(-180.0));
  }
  CGContextDrawImage(bitmap, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
  _imageRef = CGBitmapContextCreateImage(bitmap);
  CGContextRelease(bitmap);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setImage:(UIImage*)image {
  if (image != _image) {
    [_image release];
    _image = [image retain];

    //MVR - added to handle image orientation
    [self setImageRef:image];
	[self updateLayer];

    CGRect frame = self.frame;
    if (_autoresizesToImage) {
      self.width = image.size.width;
      self.height = image.size.height;

    } else {
      // Logical flow:
      // If no width or height have been specified, then autoresize to the image.
      if (!frame.size.width && !frame.size.height) {
        self.width = image.size.width;
        self.height = image.size.height;

      // If a width was specified, but no height, then resize the image with the correct aspect
      // ratio.

      } else if (frame.size.width && !frame.size.height) {
        self.height = floor((image.size.height/image.size.width) * frame.size.width);

      // If a height was specified, but no width, then resize the image with the correct aspect
      // ratio.

      } else if (frame.size.height && !frame.size.width) {
        self.width = floor((image.size.width/image.size.height) * frame.size.height);
      }

      // If both were specified, leave the frame as is.
    }

    if (nil == _defaultImage || image != _defaultImage) {
      // Only send the notification if there's no default image or this is a new image.
      [self imageViewDidLoadImage:image];
      if ([_delegate respondsToSelector:@selector(imageView:didLoadImage:)]) {
        [_delegate imageView:self didLoadImage:image];
      }
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setStyle:(TTStyle*)style {
  if (style != _style) {
    [super setStyle:style];
    [self updateLayer];
  }
}


@end
