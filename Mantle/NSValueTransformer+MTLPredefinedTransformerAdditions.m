//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "NSArray+MTLHigherOrderAdditions.h"
#import "MTLModel.h"
#import "MTLValueTransformer.h"

NSString * const MTLURLValueTransformerName = @"MTLURLValueTransformerName";
NSString * const MTLBooleanValueTransformerName = @"MTLBooleanValueTransformerName";

@implementation NSValueTransformer (MTLPredefinedTransformerAdditions)

#pragma mark Category Loading

+ (void)load {
	@autoreleasepool {
		MTLValueTransformer *URLValueTransformer = [MTLValueTransformer
			reversibleTransformerWithForwardBlock:^ id (NSString *str) {
				if (![str isKindOfClass:NSString.class]) return nil;
				return [NSURL URLWithString:str];
			}
			reverseBlock:^ id (NSURL *URL) {
				if (![URL isKindOfClass:NSURL.class]) return nil;
				return URL.absoluteString;
			}];
		
		[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];

		MTLValueTransformer *booleanValueTransformer = [MTLValueTransformer
			reversibleTransformerWithBlock:^ id (NSNumber *boolean) {
				if (![boolean isKindOfClass:NSNumber.class]) return nil;
				return (NSNumber *)(boolean.boolValue ? kCFBooleanTrue : kCFBooleanFalse);
			}];

		[NSValueTransformer setValueTransformer:booleanValueTransformer forName:MTLBooleanValueTransformerName];
	}
}

#pragma mark Customizable Transformers

+ (NSValueTransformer *)mtl_JSONTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);

	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(id externalRepresentation) {
			return [modelClass modelWithExternalRepresentation:externalRepresentation inFormat:MTLModelJSONFormat];
		}
		reverseBlock:^(MTLModel *model) {
			return [model externalRepresentationInFormat:MTLModelJSONFormat];
		}];
}

+ (NSValueTransformer *)mtl_JSONArrayTransformerWithModelClass:(Class)modelClass {
	NSValueTransformer *individualTransformer = [self mtl_JSONTransformerWithModelClass:modelClass];

	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSArray *representations) {
			return [representations mtl_mapUsingBlock:^(id externalRepresentation) {
				return [individualTransformer transformedValue:externalRepresentation];
			}];
		}
		reverseBlock:^(NSArray *models) {
			return [models mtl_mapUsingBlock:^(MTLModel *model) {
				return [individualTransformer reverseTransformedValue:model];
			}];
		}];
}

#pragma mark Deprecated methods

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (NSValueTransformer *)mtl_externalRepresentationTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass isSubclassOfClass:MTLModel.class]);

	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(id externalRepresentation) {
			return [modelClass modelWithExternalRepresentation:externalRepresentation inFormat:MTLModelKeyedArchiveFormat];
		}
		reverseBlock:^(MTLModel *model) {
			return [model externalRepresentationInFormat:MTLModelKeyedArchiveFormat];
		}];
}

+ (NSValueTransformer *)mtl_externalRepresentationArrayTransformerWithModelClass:(Class)modelClass {
	NSValueTransformer *individualTransformer = [self mtl_externalRepresentationTransformerWithModelClass:modelClass];

	return [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSArray *representations) {
			return [representations mtl_mapUsingBlock:^(id externalRepresentation) {
				return [individualTransformer transformedValue:externalRepresentation];
			}];
		}
		reverseBlock:^(NSArray *models) {
			return [models mtl_mapUsingBlock:^(MTLModel *model) {
				return [individualTransformer reverseTransformedValue:model];
			}];
		}];
}

#pragma clang diagnostic pop

@end
