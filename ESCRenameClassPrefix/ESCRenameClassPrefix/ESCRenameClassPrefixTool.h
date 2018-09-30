//
//  ESCReNameClassPrefixTool.h
//  ESCReplaceClassNamePrefix
//
//  Created by xiang on 2018/9/30.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESCRenameClassPrefixTool : NSObject

- (NSMutableDictionary *)readAllClassFileAndSaveToPlistFile:(NSString *)path;

- (void)replaceClassNameWithDirectPath:(NSString *)path
                           projectPath:(NSString *)projectPath
                             oldPrefix:(NSString *)oldPrefix
                             newPrefix:(NSString *)newPrefix
                             className:(NSDictionary *)classNameDictionary;

@end

NS_ASSUME_NONNULL_END
