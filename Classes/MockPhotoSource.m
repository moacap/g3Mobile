#import "MockPhotoSource.h"
#import "MyAlbum.h"
#import "AppDelegate.h"

@implementation MockPhotoSource

@synthesize title = _title;
@synthesize albumID = _albumID;
@synthesize parentURL = _parentURL;

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)fakeLoadReady {
	_fakeLoadTimer = nil;

	if (_type & MockPhotoSourceLoadError) {
		[_delegates perform:@selector(model:didFailLoadWithError:)
		         withObject:self
		         withObject:nil];
	}
	else {
		NSMutableArray *newPhotos = [NSMutableArray array];

		for (int i = 0; i < _photos.count; ++i) {
			id <TTPhoto> photo = [_photos objectAtIndex:i];
			if ( (NSNull *)photo != [NSNull null] ) {
				[newPhotos addObject:photo];
			}
		}

		[newPhotos addObjectsFromArray:_tempPhotos];
		TT_RELEASE_SAFELY(_tempPhotos);

		[_photos release];
		_photos = [newPhotos retain];

		for (int i = 0; i < _photos.count; ++i) {
			id <TTPhoto> photo = [_photos objectAtIndex:i];
			if ( (NSNull *)photo != [NSNull null] ) {
				photo.photoSource = self;
				photo.index = i;
			}
		}

		[_delegates perform:@selector(modelDidFinishLoad:) withObject:self];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithType:(MockPhotoSourceType)type parentURL:(NSString *)parentURL albumID:(NSString *)albumID title:(NSString *)title photos:(NSArray *)photos
       photos2:(NSArray *)photos2 {
	if (self = [super init]) {
		_type = type;
		_parentURL = [parentURL retain];
		_albumID = [albumID retain];
		_title = [title retain];
		_photos = photos2 ? [photos mutableCopy] : [[NSMutableArray alloc] init];
		_tempPhotos = photos2 ? [photos2 retain] : [photos retain];
		_fakeLoadTimer = nil;

		for (int i = 0; i < _photos.count; ++i) {
			id <TTPhoto> photo = [_photos objectAtIndex:i];
			if ( (NSNull *)photo != [NSNull null] ) {
				photo.photoSource = self;
				photo.index = i;
			}
		}

		if ( !(_type & MockPhotoSourceDelayed || photos2) ) {
			[self performSelector:@selector(fakeLoadReady)];
		}
	}
	return self;
}

- (id)init {
	return [self initWithType:MockPhotoSourceNormal title:nil photos:nil photos2:nil];
}

- (void)dealloc {
	[_fakeLoadTimer invalidate];
	TT_RELEASE_SAFELY(_photos);
	TT_RELEASE_SAFELY(_tempPhotos);
	TT_RELEASE_SAFELY(_title);

	TT_RELEASE_SAFELY(_albumID);
	TT_RELEASE_SAFELY(_parentURL);

	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTModel

- (BOOL)isLoading {
	return !!_fakeLoadTimer;
}

- (BOOL)isLoaded {
	return !!_photos;
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
	if (cachePolicy & TTURLRequestCachePolicyNetwork) {
		[_delegates perform:@selector(modelDidStartLoad:) withObject:self];

		TT_RELEASE_SAFELY(_photos);
		_fakeLoadTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self
		                                                selector:@selector(fakeLoadReady) userInfo:nil repeats:NO];
	}
}

- (void)cancel {
	[_fakeLoadTimer invalidate];
	_fakeLoadTimer = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTPhotoSource

- (NSInteger)numberOfPhotos {
	if (_tempPhotos) {
		return _photos.count + (_type & MockPhotoSourceVariableCount ? 0 : _tempPhotos.count);
	}
	else {
		return _photos.count;
	}
}

- (NSInteger)maxPhotoIndex {
	return _photos.count - 1;
}

- (id <TTPhoto>)photoAtIndex:(NSInteger)photoIndex {
	if (photoIndex < _photos.count) {
		id photo = [_photos objectAtIndex:photoIndex];
		if (photo == [NSNull null]) {
			return nil;
		}
		else {
			return photo;
		}
	}
	else {
		return nil;
	}
}

static MockPhotoSource *_samplePhotoSet = nil;
+ (MockPhotoSource *)samplePhotoSet {
	@synchronized(self) {
		if (_samplePhotoSet == nil) {
			MockPhoto *mathNinja = [[[MockPhoto alloc]
			                         initWithURL:@"http://www.raywenderlich.com/downloads/math_ninja_large.png"
			                            smallURL:@"bundle://math_ninja_small.png"
			                                size:CGSizeMake(100, 75)
			                             isAlbum:NO
			                             photoID:@"1"
			                           parentURL:nil] autorelease];
			MockPhoto *instantPoetry = [[[MockPhoto alloc]
			                             initWithURL:@"http://www.raywenderlich.com/downloads/instant_poetry_large.png"
			                                smallURL:@"bundle://instant_poetry_small.png"
			                                    size:CGSizeMake(100, 75)
			                                 isAlbum:NO
			                                 photoID:@"2"
			                               parentURL:nil] autorelease];
			MockPhoto *rpgCalc = [[[MockPhoto alloc]
			                       initWithURL:@"http://www.raywenderlich.com/downloads/rpg_calc_large.png"
			                          smallURL:@"bundle://rpg_calc_small.png"
			                              size:CGSizeMake(100, 75)
			                           isAlbum:NO
			                           photoID:@"3"
			                         parentURL:nil] autorelease];

			/*MockPhoto *levelMeUp = [[[MockPhoto alloc] initWithCaption:@"Level Me Up"
			                                                                                                              urlLarge:@"http://www.raywenderlich.com/downloads/level_me_up_large.png"
			                                                                                                              urlSmall:@"bundle://level_me_up_small.png"
			                                                                                                              urlThumb:@"bundle://level_me_up_thumb.png"
			                                                                                                                      size:CGSizeMake(1024, 768)] autorelease];

			 */
			NSArray *photos = [NSArray arrayWithObjects:mathNinja, instantPoetry, rpgCalc /*, levelMeUp*/, nil];
			//_samplePhotoSet = [[self alloc] initWithTitle:@"My Apps" photos:photos];
			_samplePhotoSet = [[self alloc] initWithType:MockPhotoSourceNormal parentURL:nil albumID:nil title:@"test" photos:photos
			                                     photos2:nil];
		}
	}
	return _samplePhotoSet;
}

+ (MockPhotoSource*)createPhotoSource:(NSString*)albumID {

	NSMutableArray* album = [[NSMutableArray alloc] init];
	MyAlbum* g3Album = [[MyAlbum alloc] initWithID:albumID];
	
	
	//NSArray* sortedKeys = [[g3Album.arraySorted allKeys] keysSortedByValueUsingSelector:@selector(compare:)];
	
	NSSortDescriptor * frequencyDescriptor =
    [[[NSSortDescriptor alloc] initWithKey:@"sortKey"
                                 ascending:YES] autorelease];
	NSArray * descriptors =
    [NSArray arrayWithObjects:frequencyDescriptor, nil];

	
	NSArray * sortedArray =
    [g3Album.arraySorted sortedArrayUsingDescriptors:descriptors];

	NSEnumerator * enumerator = [sortedArray objectEnumerator];
	id obj;
	while ((obj = [enumerator nextObject])) {
		NSDictionary* entity = [obj objectForKey:@"entity"];
		
		if (![[entity objectForKey:@"type"] isEqualToString:@"photo"]) continue;

		NSString* thumb_url = [entity objectForKey:@"thumb_url_public"];
		if (thumb_url == nil) {
			thumb_url = [entity objectForKey:@"thumb_url"];
			if (thumb_url == nil) {
				thumb_url = @"bundle://empty.png";
			}
		}
		
		NSString* resize_url = [entity objectForKey:@"resize_url_public"];
		if (resize_url == nil) {
			resize_url = [entity objectForKey:@"resize_url"];
			if (resize_url == nil) {
				resize_url = thumb_url;
				if (resize_url == nil) {
					resize_url = @"bundle://empty.png";
				}
			}
		}
		
		BOOL isAlbum;
		if ([(NSString *)[entity objectForKey:@"type"] isEqualToString:@"album"]) {
			isAlbum = YES;
		} else {
			isAlbum = NO;
		}
		
		NSString* parent = [entity objectForKey:@"parent"];
		if (parent == nil) {
			parent = @"1";
		}
		
		NSString* photoID = [entity objectForKey:@"id"];
		if (photoID == nil) {
			photoID = @"1";
		}
		
		id iWidth = [entity objectForKey:@"resize_width"];
		id iHeight = [entity objectForKey:@"resize_height"];
		
		short int width = 100;
		short int height = 100;
		
		if ([iWidth isKindOfClass:[NSString class]] && [iHeight isKindOfClass:[NSString class]]) {
			if ([@"" isEqualToString:iWidth] || [@"" isEqualToString:iHeight]) {
				width = 100;
				height = 100;
			}	
			else if ([iWidth length] > 0 && [iHeight length] > 0 ) {
				width = [iWidth longLongValue];
				height = [iHeight longLongValue];
			}
		}
		
		MockPhoto* mph = [[[MockPhoto alloc]
						   initWithURL:[NSString stringWithString: resize_url]
						   smallURL:[NSString stringWithString: thumb_url]
						   size:CGSizeMake(width, height)
						   isAlbum:isAlbum
						   photoID:[NSString stringWithString: photoID]
						   parentURL:[NSString stringWithString: parent]] autorelease];
		
		[album addObject:mph];
	}
	
	NSString* albumParent = nil;
	NSString* albumTitle = nil;
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if ([g3Album.albumEntity count] > 0) {
		if ([g3Album.albumEntity valueForKey:@"parent"] != nil) {
			albumParent = [g3Album.albumEntity valueForKey:@"parent"];
		} else {
			albumParent = [appDelegate.baseURL stringByAppendingString:@"/rest/item/1"];
		}
		if ([g3Album.albumEntity valueForKey:@"title"] != nil) {
			albumTitle = [g3Album.albumEntity valueForKey:@"title"];
		} else {
			albumTitle = @"";
		}
	} else {		
		albumParent = [appDelegate.baseURL stringByAppendingString:@"/rest/item/1"];
	}
	
	MockPhotoSource* photoSource = [[[self alloc]
						 initWithType:MockPhotoSourceNormal
						 parentURL:[NSString stringWithString: albumParent]
						 albumID:[NSString stringWithString: albumID]
						 title:albumTitle
						 photos:album
						 photos2:nil] autorelease];
	
	TT_RELEASE_SAFELY(album);
	TT_RELEASE_SAFELY(g3Album);
	
	return photoSource;
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MockPhoto

@synthesize photoSource = _photoSource, size = _size, index = _index, caption = _caption,
            isAlbum = _isAlbum, photoID = _photoID, parentURL = _parentURL;

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithURL:(NSString *)URL smallURL:(NSString *)smallURL size:(CGSize)size isAlbum:(BOOL)isAlbum photoID:(NSString *)photoID parentURL:(NSString *)parentURL {
	return [self initWithURL:URL smallURL:smallURL size:size caption:nil isAlbum:isAlbum photoID:photoID parentURL:parentURL];
}

- (id)initWithURL:(NSString *)URL smallURL:(NSString *)smallURL size:(CGSize)size
       caption:(NSString *)caption isAlbum:(BOOL)isAlbum photoID:(NSString *)photoID parentURL:(NSString *)parentURL {
	if (self = [super init]) {
		_photoSource = nil;
		_URL = [URL copy];
		_smallURL = [smallURL copy];
		_thumbURL = [smallURL copy];
		_size = size;
		_caption = [caption copy];
		_index = NSIntegerMax;
		_isAlbum = isAlbum;
		_photoID = [photoID copy];
		_parentURL = [parentURL copy];
	}
	return self;
}

- (void)dealloc {
	TT_RELEASE_SAFELY(_thumbURL);
	TT_RELEASE_SAFELY(_smallURL);
	TT_RELEASE_SAFELY(_URL);
	TT_RELEASE_SAFELY(_caption);
	TT_RELEASE_SAFELY(_photoID);
	TT_RELEASE_SAFELY(_parentURL);
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTPhoto

- (NSString *)URLForVersion:(TTPhotoVersion)version {
	if (version == TTPhotoVersionLarge) {
		return _URL;
	}
	else if (version == TTPhotoVersionMedium) {
		return _URL;
	}
	else if (version == TTPhotoVersionSmall) {
		return _smallURL;
	}
	else if (version == TTPhotoVersionThumbnail) {
		return _thumbURL;
	}
	else {
		return nil;
	}
}

@end