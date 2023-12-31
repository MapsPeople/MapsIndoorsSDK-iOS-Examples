//
//  MPDistanceMatrixProvider.h
//  MapsIndoors
//
//  Created by Daniel Nielsen on 21/09/15.
//  Copyright (c) 2015 MapsPeople A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPDistanceMatrixResult.h"

NS_ASSUME_NONNULL_BEGIN

@class MPUserRole;
typedef void(^mpMatrixHandlerBlockType)(MPDistanceMatrixResult* _Nullable matrixResult, NSError* _Nullable error);

/// > Warning: [INTERNAL - DO NOT USE]
@protocol MPDistanceMatrixProviderDelegate <NSObject>
/**
 Distance matrix result ready event.
 - Parameter distanceMatrixResult: The resulting distance matrix.
 */
@required
- (void) onDistanceMatrixResultReady: (nonnull MPDistanceMatrixResult*)distanceMatrixResult;
@end


#pragma mark - [INTERNAL - DO NOT USE]

/// > Warning: [INTERNAL - DO NOT USE]
@interface MPDistanceMatrixProvider : NSObject

@property (nonatomic, weak, nullable) id <MPDistanceMatrixProviderDelegate> delegate;
@property (nonatomic, strong, nullable) NSString* solutionId;
@property (nonatomic, strong, nullable) NSString* graphId;
@property (nonatomic, strong, nullable) NSString* vehicle;

#pragma mark - MapsIndoors distance matrix

- (void) getDistanceMatrixWithOrigins:(NSArray<NSString*>*)origins
                         destinations:(NSArray<NSString*>*)destinations
                           travelMode:(NSString*)travelMode
                                avoid:(nullable NSArray<NSString*>*)restrictions
                               depart:(nullable NSDate*)departureTime
                               arrive:(nullable NSDate*)arrivalTime
                            userRoles:(nullable NSArray<MPUserRole*>*)userRoles
                    completionHandler:(nullable mpMatrixHandlerBlockType)handler;

- (void) getDistanceMatrixWithOrigins:(NSArray<NSString*>*)origins
                         destinations:(NSArray<NSString*>*)destinations
                           travelMode:(NSString*)travelMode
                                avoid:(nullable NSArray<NSString*>*)restrictions
                               depart:(nullable NSDate*)departureTime
                               arrive:(nullable NSDate*)arrivalTime
                    completionHandler:(nullable mpMatrixHandlerBlockType)handler;

- (void) getDistanceMatrixWithOrigins:(NSArray<NSString*>*)origins
                         destinations:(NSArray<NSString*>*)restrictions
                           travelMode:(NSString*)travelMode;

@end

NS_ASSUME_NONNULL_END
