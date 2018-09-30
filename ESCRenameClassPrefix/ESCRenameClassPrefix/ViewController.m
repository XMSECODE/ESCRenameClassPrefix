//
//  ViewController.m
//  ESCReplaceClassNamePrefix
//
//  Created by xiang on 2018/9/29.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import "ESCRenameClassPrefixTool.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *targetTextField;
@property (weak) IBOutlet NSTextField *xcodeprojTextField;
@property (weak) IBOutlet NSTextField *oldPrefixTextField;
@property (weak) IBOutlet NSTextField *currentPrefixTextField;

@property(nonatomic,strong)NSMutableDictionary* classNameDictionary;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"path"];
    NSString *xcodeproj = [[NSUserDefaults standardUserDefaults] objectForKey:@"xcodeproj"];
    NSString *oldPrefix = [[NSUserDefaults standardUserDefaults] objectForKey:@"oldPrefix"];
    NSString *currentPrefix = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentPrefix"];
    
    //判断
    if (path != nil || path.length > 0) {
        self.targetTextField.stringValue = path;
    }
    if (xcodeproj != nil || xcodeproj.length > 0) {
        self.xcodeprojTextField.stringValue = xcodeproj;
    }
    if (oldPrefix != nil || oldPrefix.length > 0) {
        self.oldPrefixTextField.stringValue = oldPrefix;
    }
    if (currentPrefix != nil || currentPrefix.length > 0) {
        self.currentPrefixTextField.stringValue = currentPrefix;
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

}
- (IBAction)didClickSaveButton:(id)sender {
    
    NSString *path = self.targetTextField.stringValue;
    NSString *xcodeproj = self.xcodeprojTextField.stringValue;
    NSString *oldPrefix = self.oldPrefixTextField.stringValue;
    NSString *currentPrefix = self.currentPrefixTextField.stringValue;
    
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"path"];
    [[NSUserDefaults standardUserDefaults] setObject:xcodeproj forKey:@"xcodeproj"];
    [[NSUserDefaults standardUserDefaults] setObject:oldPrefix forKey:@"oldPrefix"];
    [[NSUserDefaults standardUserDefaults] setObject:currentPrefix forKey:@"currentPrefix"];
    
}

- (IBAction)didClickStartButton:(id)sender {
    
    NSString *path = self.targetTextField.stringValue;
    NSString *xcodeproj = self.xcodeprojTextField.stringValue;
    NSString *oldPrefix = self.oldPrefixTextField.stringValue;
    NSString *currentPrefix = self.currentPrefixTextField.stringValue;
    
    //判断
    if (path == nil || path.length == 0) {
        return;
    }
    if (xcodeproj == nil || xcodeproj.length == 0) {
        return;
    }
    if (oldPrefix == nil || oldPrefix.length == 0) {
        return;
    }
    if (currentPrefix == nil || currentPrefix.length == 0) {
        return;
    }
    
    [self replaceClassPrefixWithDirectPath:path projectPath:xcodeproj oldPrefix:oldPrefix newPrefix:currentPrefix];
    
}

- (void)replaceClassPrefixWithDirectPath:(NSString *)path projectPath:(NSString *)projectPath oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix {
    
    ESCRenameClassPrefixTool *tool = [[ESCRenameClassPrefixTool alloc] init];
    self.classNameDictionary = [NSMutableDictionary dictionary];
    //读取并记录所有文件的类名
    self.classNameDictionary =  [tool readAllClassFileAndSaveToPlistFile:path];
    
    //遍历每个文件，根据读取记录的类名更创建新文件类
    [tool replaceClassNameWithDirectPath:path projectPath:projectPath oldPrefix:oldPrefix newPrefix:newPrefix className:self.classNameDictionary];
    
}



@end
