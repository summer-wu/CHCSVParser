#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

@interface Delegate : NSObject <CHCSVParserDelegate>

@property (readonly) NSArray *lines;

@end

@implementation Delegate {
    NSMutableArray *_lines;
    NSMutableArray *_currentLineArray;//当前行
    NSInteger _currentLineNo;//当前行号
    NSMutableArray *_firstLineFields;//首行是字段名
}
- (void)parserDidBeginDocument:(CHCSVParser *)parser {
    _lines = [[NSMutableArray alloc] init];
}
- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber {
    _currentLineNo += 1;
    if (1==_currentLineNo) {
        _firstLineFields = [NSMutableArray array];
    } else {
        _currentLineArray = [NSMutableArray array];
    }
}
- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
    NSLog(@"%@", field);
    if (1==_currentLineNo) {
        [_firstLineFields addObject:field];
    } else {
        [_currentLineArray addObject:field];
    }
}
- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
    if (1==_currentLineNo) {
        NSLog(@"首行结束");
    } else {
        CHCSVOrderedDictionary *currentLineDict = [[CHCSVOrderedDictionary alloc]initWithObjects:_currentLineArray forKeys:_firstLineFields];
        [_lines addObject:currentLineDict];
        _currentLineArray = nil;
    }
}

+ (NSString *)toJSONString:(id)obj{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:0
                                                         error:&error];

    if (jsonData == nil) {
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (void)parserDidEndDocument:(CHCSVParser *)parser {
    NSLog(@"parser ended解析结果为: %@",_lines);
    NSLog(@"解析出的json为：%@",[Delegate toJSONString:_lines]);
}
- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
	NSLog(@"ERROR: %@", error);
    _lines = nil;
}
@end



int main (int argc, const char * argv[]) {
    @autoreleasepool {
        NSData *data = [NSData dataWithContentsOfFile:@"/Users/n/Downloads/output.json"];
        id output = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"%@",output);
        exit(0);

        NSString *file = @(__FILE__);
        file = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Test.csv"];
        NSLog(@"file:%@",file);
        NSLog(@"Beginning...");
        NSStringEncoding encoding = 0;
        NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:file];
        CHCSVParser * p = [[CHCSVParser alloc] initWithInputStream:stream usedEncoding:&encoding delimiter:'\t'];
        [p setRecognizesBackslashesAsEscapes:YES];
        [p setSanitizesFields:YES];
        
        NSLog(@"encoding: %@", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)));
        
        Delegate * d = [[Delegate alloc] init];
        [p setDelegate:d];
        
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        [p parse];
        NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
        
        NSLog(@"raw difference: %f", (end-start));
        
        NSLog(@"%@", [d lines]);
    }
    return 0;
}
