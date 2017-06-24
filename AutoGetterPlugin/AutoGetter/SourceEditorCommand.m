//
//  SourceEditorCommand.m
//  AutoGetter
//
//  Created by HChong on 2017/6/23.
//  Copyright © 2017年 HChong. All rights reserved.
//

#import "SourceEditorCommand.h"
#import "SourceEditorHeader.h"
#import <Cocoa/Cocoa.h>

@interface SourceEditorCommand()

@property (nonatomic, strong) NSMutableArray *propretyArray;
@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    [self.propretyArray removeAllObjects];
    //插件执行类的所有行的内容
    NSArray *stringArray = [NSArray arrayWithArray:invocation.buffer.lines];
    if (stringArray.count == 0) {
        return;
    }
    
    for (NSString *lineString in stringArray) {
        [self handleString:lineString];
    }
    
    completionHandler(nil);
}

//对每一行进行处理
- (void)handleString:(NSString *)string {
    if ([self matchProperty:string]) {
        NSString *getterString = [self packageGetterWith:string];
        [self insertGetterStringToClass:getterString];
    }
}

//组装Getter方法
- (NSString *)packageGetterWith:(NSString *)lineString {
    if (![lineString containsString:@"IBOutlet"] && ![lineString containsString:@"^"] && ![lineString containsString:@"//"]) {
        NSString *className = [self getClassName:lineString];
        NSString *objectName = [self getClassName:lineString];
        return [self makeResultString:className objectName:objectName];
    }
    return @"";
}

//插入到源代码固定位置
- (void)insertGetterStringToClass:(NSString *)getterString {
    
}

#pragma mark - Private
//判断该行是否是属性定义行
- (BOOL)matchProperty:(NSString *)string {
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^@property.*;\\n$"];
    return [pre evaluateWithObject:string];
}

//拿到类名
- (NSString *)getClassName:(NSString *)lineString {
    NSArray *propertyDescription = [lineString componentsSeparatedByString:@")"];
    propertyDescription = [[propertyDescription lastObject] componentsSeparatedByString:@"*"];
    return [propertyDescription firstObject];
}

//拿到类的对象
- (NSString *)getObjectName:(NSString *)lineString {
    NSRange range = [lineString rangeOfString:@"\\*.*;" options:NSRegularExpressionSearch];
    NSString *string = [lineString substringWithRange:range];
    
    NSRange range2 = [string rangeOfString:@"[a-zA-Z0-9_]+" options:NSRegularExpressionSearch];
    NSString *obejctName = [string substringWithRange:range2];
    return obejctName;
}

//判断属性的修饰符
- (NSString *)getPropretyModifier:(NSString *)lineString {
    return @"";
}

//根据不同的类生成不同的Getter方法
- (NSString *)makeResultString:(NSString *)className objectName:(NSString *)objectName{
    if ([className isEqualToString:Class_CGFloat] || [className isEqualToString:Class_Bool] || [className isEqualToString:Class_NSInteger]) {
        return @"";
    }
    
    if ([className isEqualToString:Class_UIView] || [className isEqualToString:Class_UIImageView]) {
        NSString *resultString;
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@", className, objectName];
        NSString *line2 = [NSString stringWithFormat:@"{"];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", objectName, className];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        return resultString;
    }
    
    if ([className isEqualToString:Class_UITextView] || [className isEqualToString:Class_UITextField] || [className isEqualToString:Class_UILabel] || [className isEqualToString:Class_UISearchBar]) {
        return @"";
    }
    
    if ([className isEqualToString:Class_UIButton]) {
        return @"";
    }
    
    if ([className isEqualToString:Class_UITableView]) {
        return @"";
    }
    
    if ([className isEqualToString:Class_UICollectionView]) {
        return @"";
    }
    
    if ([className isEqualToString:Class_UIScrollView]) {
        return @"";
    }
    
    NSString *resultString;
    return resultString;
}

#pragma mark - Getter
- (NSMutableArray *)propretyArray{
    if (!_propretyArray) {
        _propretyArray = [NSMutableArray array];
    }
    return _propretyArray;
}

@end
