//
//  SourceEditorCommand.m
//  AutoImport
//
//  Created by HChong on 2017/6/26.
//  Copyright © 2017年 HChong. All rights reserved.
//

#import "SourceEditorCommand.h"

@interface SourceEditorCommand()

@property (nonatomic, assign) NSInteger startLineNumber;
@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    XCSourceTextRange *range = [invocation.buffer.selections firstObject];
    
    NSString *selectedLines = [invocation.buffer.lines objectAtIndex:range.start.line];
    NSString *selection = [selectedLines substringWithRange:NSMakeRange(range.start.column, range.end.column - range.start.column)];
    
    for (NSInteger i = 0; i < invocation.buffer.lines.count - 1; i++) {
        NSString *importString = [invocation.buffer.lines objectAtIndex:i];
        if ([importString containsString:@"@implementation"]) {
            self.startLineNumber = i;
        }
        if ([importString containsString:@"@interface"]) {
            self.startLineNumber = i;
            break;
        }
    }
    
    BOOL isImported = NO;
    for (NSInteger i = 0; i <= self.startLineNumber ; i++) {
        NSString *importString = [invocation.buffer.lines objectAtIndex:i];
        if ([importString containsString:[NSString stringWithFormat:@"%@.h", selection]]) {
            isImported = YES;
            break;
        }
    }
    if (isImported == NO) {
        [invocation.buffer.lines insertObject:[NSString stringWithFormat:@"#import \"%@.h\"", selection] atIndex:self.startLineNumber - 1];
    }

    
    completionHandler(nil);
}

@end
