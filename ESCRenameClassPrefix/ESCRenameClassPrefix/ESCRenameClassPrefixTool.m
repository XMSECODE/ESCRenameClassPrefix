//
//  ESCReNameClassPrefixTool.m
//  ESCReplaceClassNamePrefix
//
//  Created by xiang on 2018/9/30.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ESCRenameClassPrefixTool.h"

@interface ESCRenameClassPrefixTool ()

@end

@implementation ESCRenameClassPrefixTool

#pragma mark - 递归读取文件
- (void)readAllFileWithPath:(NSString *)path childPath:(void(^)(NSString *childPath))childPathBlock {
    //递归，判断当前为文件还是文件夹
    NSError *error = nil;
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    if (isExists == NO) {
        NSLog(@"%@:路径不存在",path);
        return;
    }
    //    NSLog(@"%@",path);
    if (isDir) {
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
        if (error == nil) {
            for (NSString *subPath in array) {
                NSString *newPath = [[path mutableCopy] stringByAppendingPathComponent:subPath];
                [self readAllFileWithPath:newPath childPath:childPathBlock];
            }
            return;
        }else {
            NSLog(@"%@:读取文件失败",error);
            return;
        }
    } else {
        childPathBlock(path);
    }
}

#pragma mark - 读取所有文件类名
- (NSMutableDictionary *)readAllClassFileAndSaveToPlistFile:(NSString *)path {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self readAllFileWithPath:path childPath:^(NSString *childPath) {
        NSString *name = [childPath lastPathComponent];
        NSString *classExtension = name.pathExtension;
        if (!([classExtension isEqualToString:@"h"] || [classExtension isEqualToString:@"m"])) {
            return;
        }else {
            //类文件,记录类名
            NSString *className = name.stringByDeletingPathExtension;
            [dict setValue:@"" forKey:className];
        }
    }];
    return dict;
}

#pragma mark - 创建新的类文件
- (void)replaceClassNameWithDirectPath:(NSString *)path projectPath:(NSString *)projectPath oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix className:(NSDictionary *)classNameDictionary{
    //判断生成需要替换的类的字典
    NSMutableDictionary *newClassNameDict = [NSMutableDictionary dictionary];
    for (NSString *key in classNameDictionary) {
        NSString *value = @"";
        if (key.length > oldPrefix.length) {
            NSString *keyPrefix = [key substringToIndex:oldPrefix.length];
            if ([keyPrefix isEqualToString:oldPrefix]) {
                //创建新的类名
                value = [key substringFromIndex:oldPrefix.length];
                value = [NSString stringWithFormat:@"%@%@",newPrefix,value];
            }
        }
        [newClassNameDict setValue:value forKey:key];
    }
    NSLog(@"%@",newClassNameDict);
    NSString *classPlistPath = [NSString stringWithFormat:@"%@/class.plist",path];
    [newClassNameDict writeToFile:classPlistPath atomically:YES];
    [self replaceClassNameWithDirectPath:path projectPath:projectPath className:newClassNameDict];
}

- (void)replaceClassNameWithDirectPath:(NSString *)path projectPath:(NSString *)projectPath className:(NSDictionary *)classNameDictionary{
    //遍历文件替换
    [self readAllFileWithPath:path childPath:^(NSString *childPath) {
        //判断文件后缀
        NSString *name = [childPath lastPathComponent];
        NSString *cName = [name stringByDeletingPathExtension];
        NSString *classExtension = name.pathExtension;
        if (!([classExtension isEqualToString:@"h"] || [classExtension isEqualToString:@"m"] || [classExtension isEqualToString:@"mm"] || [classExtension isEqualToString:@"swift"] || [classExtension isEqualToString:@"xib"] || [classExtension isEqualToString:@"storyboard"])) {
            return;
        }
        //读取旧文件
        NSLog(@"%@",childPath);
        NSError *error = nil;
        NSMutableString *content = [NSMutableString stringWithContentsOfFile:childPath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"打开文件失败：%@==%@",childPath,error.description);
            return;
        }
        //修改读取内容
        for (NSString *key in classNameDictionary) {
            NSString *value = [classNameDictionary valueForKey:key];
            if (value.length > 0) {
                NSString *regularExpression = [NSString stringWithFormat:@"\\b%@\\b", key];
                NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
                NSArray <NSTextCheckingResult *> *matches = [expression matchesInString:content options:0 range:NSMakeRange(0, content.length)];
                [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [content replaceCharactersInRange:obj.range withString:value];
                }];
            }
        }
        
        //创建新文件
        NSString *newName = classNameDictionary[cName];
        if (newName == nil || newName.length <= 0 || [newName isEqualToString:@""]) {
            newName = name;
        }else {
            newName = [NSString stringWithFormat:@"%@.%@",classNameDictionary[cName],classExtension];
        }
        NSString *newFilePath = [NSString stringWithFormat:@"%@/%@",childPath.stringByDeletingLastPathComponent,newName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:newFilePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:newFilePath error:nil];
        }
        //        NSLog(@"newfilepath ==  %@==%@",newFilePath,content);
        //写入新文件
        [content writeToFile:newFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"写入新文件失败%@==%@",newFilePath,error);
            return;
        }
        if ([newFilePath isEqualToString:childPath]) {
            return;
        }
        //删除旧文件
        [[NSFileManager defaultManager] removeItemAtPath:childPath error:&error];
        if (error) {
            NSLog(@"删除旧文件失败%@==%@",childPath,error);
            return;
        }
    }];
    //修改项目管理文件
    NSString *settingString = [NSString stringWithFormat:@"%@/project.pbxproj", projectPath];
    [self replaceProjectClassNameDictionary:classNameDictionary filePath:settingString];
}

- (void)replaceProjectClassNameDictionary:(NSDictionary *)classNameDictionary filePath:(NSString *)filePath {
    //读取旧文件
    NSError *error = nil;
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"打开文件失败：%@==%@",filePath,error.description);
        return;
    }
    //修改读取内容
    for (NSString *key in classNameDictionary) {
        NSString *value = [classNameDictionary valueForKey:key];
        if (value.length > 0) {
            NSString *regularExpression = [NSString stringWithFormat:@"\\b%@\\b", key];
            NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
            NSArray <NSTextCheckingResult *> *matches = [expression matchesInString:content options:0 range:NSMakeRange(0, content.length)];
            [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [content replaceCharactersInRange:obj.range withString:value];
            }];
        }
    }
    
    //写入新文件
    [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"写入新文件失败%@==%@",filePath,error);
        return;
    }
    
}

@end
