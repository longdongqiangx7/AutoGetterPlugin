//
//  SourceEditorCommand.m
//  AutoGetter
//
//  Created by HChong on 2017/6/23.
//  Copyright © 2017年 HChong. All rights reserved.
//

#import "SourceEditorCommand.h"
#import "SourceEditorHeader.h"

@interface SourceEditorCommand()

@property (nonatomic, strong) NSMutableArray *propretyArray;
@property (nonatomic, strong) XCSourceEditorCommandInvocation *invocation;
@property (nonatomic, assign) NSInteger endLineNumber;
@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    XCSourceTextRange *range = [invocation.buffer.selections firstObject];
    NSInteger startLineNumber = range.start.line;
    NSInteger endLineNumber = range.end.line;
    self.invocation = invocation;
    [self.propretyArray removeAllObjects];
    //插件执行类的所有行的内容
    NSArray *stringArray = [NSArray arrayWithArray:invocation.buffer.lines];
    if (stringArray.count == 0) {
        return;
    }
    
    for (NSInteger i = stringArray.count; i > 0; i--) {
        NSString *lineString = stringArray[i - 1];
        if ([lineString containsString:@"@end"] && !self.endLineNumber) {
            self.endLineNumber = i - 2;
        }
    }
    
    for (NSInteger i = startLineNumber; i <= endLineNumber; i++) {
        NSString *lineString = stringArray[i];
        [self handleString:lineString];
    }

    completionHandler(nil);
}

//对每一行进行处理
- (void)handleString:(NSString *)string {
    if ([self matchProperty:string]) {
        NSArray *getterStringArray = [self packageGetterWith:string];
        [self insertGetterStringToClass:getterStringArray];
    }
}

//组装Getter方法
- (NSArray *)packageGetterWith:(NSString *)lineString {
    if (![lineString containsString:@"IBOutlet"] && ![lineString containsString:@"^"] && ![lineString hasPrefix:@"//"] && ![lineString containsString:@"assign"]) {
        NSString *className = [self getClassName:lineString];
        NSString *objectName = [self getObjectName:lineString];
        return [self makeResultString:className objectName:objectName];
    }
    return @[];
}

//插入到源代码固定位置
- (void)insertGetterStringToClass:(NSArray *)getterStringArray {
    for (int i = 0; i < getterStringArray.count; i++) {
        [self.invocation.buffer.lines insertObject:getterStringArray[i] atIndex:self.endLineNumber];
    }
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
    NSString *className = [NSString stringWithFormat:@"%@", [propertyDescription firstObject]];
    return [className stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//拿到类的对象
- (NSString *)getObjectName:(NSString *)lineString {
    NSRange range = [lineString rangeOfString:@"\\*.*;" options:NSRegularExpressionSearch];
    NSString *string = [lineString substringWithRange:range];
    
    NSRange range2 = [string rangeOfString:@"[a-zA-Z0-9_]+" options:NSRegularExpressionSearch];
    NSString *obejctName = [string substringWithRange:range2];
    return [obejctName stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//判断属性的修饰符
- (NSString *)getPropretyModifier:(NSString *)lineString {
    return @"";
}

//根据不同的类生成不同的Getter方法
- (NSArray *)makeResultString:(NSString *)className objectName:(NSString *)objectName{
    if ([className isEqualToString:Class_CGFloat] || [className isEqualToString:Class_Bool] || [className isEqualToString:Class_NSInteger]) {
        return @[];
    }
    
    if ([className isEqualToString:Class_UIView] || [className isEqualToString:Class_UIImageView]) {
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", objectName, className];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, line4, line9, line5, line6, line7, line8, nil];
        return [[lineArrays reverseObjectEnumerator] allObjects];
    }
    
    if ([className isEqualToString:Class_UITextView] || [className isEqualToString:Class_UITextField] || [className isEqualToString:Class_UILabel] || [className isEqualToString:Class_UISearchBar]) {
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", objectName, className];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line10 = [NSString stringWithFormat:@"        _%@.textColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line11 = [NSString stringWithFormat:@"        _%@.font = [UIFont systemFontOfSize:<#(CGFloat)#>];", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, line4, line9, line10, line11, line5, line6, line7, line8, nil];
        return [[lineArrays reverseObjectEnumerator] allObjects];
    }
    
    if ([className isEqualToString:Class_UIButton]) {
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ buttonWithType:UIButtonTypeCustom];", objectName, className];
        NSString *line2 = [NSString stringWithFormat:@"        [_%@ addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];", objectName];
        NSString *line10 = [NSString stringWithFormat:@"        [_%@ setTitle:@\"确定\" forState:UIControlStateNormal]", objectName];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line11 = [NSString stringWithFormat:@"        _%@.titleLabel.font = [UIFont systemFontOfSize:12];", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, line4, line2, line10, line9, line11, line5, line6, line7, line8, nil];
        return [[lineArrays reverseObjectEnumerator] allObjects];
    }
    
    if ([className isEqualToString:Class_UITableView]) {
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", objectName, className];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line2 = [NSString stringWithFormat:@"        _%@.delegate = self;", objectName];
        NSString *line10 = [NSString stringWithFormat:@"        _%@.dataSource = self;", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, line4, line9, line2, line10, line5, line6, line7, line8, nil];
        return [[lineArrays reverseObjectEnumerator] allObjects];
    }
    
    if ([className isEqualToString:Class_UICollectionView]) {
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *layout1 = [NSString stringWithFormat:@"        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];"];
        NSString *layout2 = [NSString stringWithFormat:@"        [layout setScrollDirection:UICollectionViewScrollDirectionVertical];"];
        NSString *layout3 = [NSString stringWithFormat:@""];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] initWithFrame:<#CGRectMake()#> collectionViewLayout:layout];", objectName, className];
        NSString *line2 = [NSString stringWithFormat:@"        _%@.delegate = self;", objectName];
        NSString *line10 = [NSString stringWithFormat:@"        _%@.dataSource = self;", objectName];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, layout1, layout2, layout3, line4, line2, line10, line9, line5, line6, line7, line8, nil];
        return [[lineArrays reverseObjectEnumerator] allObjects];
    }
    
    if ([className isEqualToString:Class_UIScrollView]) {
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", objectName, className];
        NSString *line10 = [NSString stringWithFormat:@"        _%@.delegate = self;", objectName];
        NSString *line11 = [NSString stringWithFormat:@"        _%@.minimumZoomScale = <#(CGFlooat)#>;", objectName];
        NSString *line12 = [NSString stringWithFormat:@"        _%@.maximumZoomScale = <#(CGFlooat)#>;", objectName];
        NSString *line13 = [NSString stringWithFormat:@"        _%@.clipsToBounds = YES;", objectName];
        NSString *line14 = [NSString stringWithFormat:@"        _%@.zoomScale = <#(CGFlooat)#>;", objectName];
        NSString *line15 = [NSString stringWithFormat:@"        _%@.contentSize = <#(CGSize)#>;", objectName];
        NSString *line16 = [NSString stringWithFormat:@"        _%@.contentOffset = <#(CGPoint)#>;", objectName];
        NSString *line9 = [NSString stringWithFormat:@"        _%@.backgroundColor = [UIColor <#whiteColor#>];", objectName];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, line4, line10, line11, line12, line13, line14, line15, line16, line9, line5, line6, line7, line8, nil];
        return [[lineArrays reverseObjectEnumerator] allObjects];
    }
    
    NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@ {", className, objectName];
    NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", objectName];
    NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", objectName, className];
    NSString *line5 = [NSString stringWithFormat:@"    }"];
    NSString *line6 = [NSString stringWithFormat:@"    return _%@;", objectName];
    NSString *line7 = [NSString stringWithFormat:@"}"];
    NSString *line8 = [NSString stringWithFormat:@""];
    NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line3, line4, line5, line6, line7, line8, nil];
    return [[lineArrays reverseObjectEnumerator] allObjects];
}

#pragma mark - Getter
- (NSMutableArray *)propretyArray{
    if (!_propretyArray) {
        _propretyArray = [NSMutableArray array];
    }
    return _propretyArray;
}

@end
