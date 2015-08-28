//
//  PPHReaderDisplayFormatter.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 1/15/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PPHDisplayReader) {
    ePPHDisplayReaderUnknown,
    ePPHDisplayReaderM010
};

/*!
 * This class allows you to generate aligned, justified strings of text for display
 * on LED screens. Most reader display screens allow a certain number of characters to be displayed
 * per row. Based on these constraints you will probably either want to right justify, left justify,
 * or simply center your strings of text on the display. Use this class to do these operations.
 * This class is simply a formatter and has no intelligence on how many lines a readerDisplay accepts.
 
 * Your strings MUST include the "\n" character to specify new lines
 * of text in your string. We apply alignment to each line separately and build out the string.
 * If your strings do not have a "\n" we logically break lines based off of how many characters were
 * defined per row.
 *
 */
@interface PPHReaderDisplayFormatter : NSObject

/*!
 * Query this property to get the current formatted string in ReaderDisplayFormatter.
 * This value can be the empty string @"" if an error occurred during formatting due
 * to bad input values. We also append @"" if subsequent formatting operations fail.
 */
@property (nonatomic, strong, readonly) NSMutableString *stringValue;

/*!
 * Grab an instance of PPHReaderDisplayFormatter by specifying the number of characters allowed 
 * per row for the current display you are working with.
 */
+ (PPHReaderDisplayFormatter *)formatterWithNumCharactersPerRow:(NSUInteger)numChars;

/*!
 * Grab an instance of PPHReaderDisplayFormatter by specifying the current Display Reader you
 * are working with. Currently we only support the m010 reader. Based on the reader provided, we init
 * the formatter with the appropriate number of characters per row. If you provide
 * ePPHDisplayReaderUnknown we return nil, for a custom formatter use the formatterWithNumCharacters
 * PerRow static initter method instead.
 */
+ (PPHReaderDisplayFormatter *)formatterForDisplayReader:(PPHDisplayReader)reader;

/*!
 * Use this method to justify/align a string.
 * @param str: The string you want formatted/aligned for the display
 * @param alignment: NSTextAlignment value to specify how you want the text aligned. Currently we only 
 * support NSTextAlignmentCenter, NSTextAlignmentRight, and NSTextAlignmentLeft. Any other enumeration
 * val passed in will result in the string being ignored and no action being taken.
 *
 * EXAMPLE: Let's say you pass in the string "Hello\nWorld" with alignment NSTextAlignmentCenter.
 * This implies you want the lines "Hello" and "World" to be on two separate lines on the display reader
 * and you want each string to be centered on the display. We format the string accordingly. After 
 * feeding the string into this API, get the formatted string back by querying the stringValue property.
 */
- (void)justifyString:(NSString *)str withAlignment:(NSTextAlignment)alignment;

/*!
 * Add a line that has a left aligned string and a right aligned string (blanks inserted in between)
 */
-(void)stringWithLeftString:(NSString*)left andRightString:(NSString*) right;

/*!
 * Provide a key prefix for a string in our string tables, this method will return the appropriate
 * text mapped to the key prefix for the formatter's current reader. You can then feed the string into
 * the formatter's API's to justify the text if you want and then retrieve the formatted text.
 */
- (NSString *)readerTextForKey:(NSString *)key;

/*!
 * Convenience method to split a string on new line characters. You can then feed each string 
 * one by one into the formatter's justifyString method and specify different alignments.
 */
- (NSArray *)splitOnNewLine:(NSString *)str;

/*!
 * Convenience method to generate a blank line of text padded with spaces and add it to
 * the formatter. This can help to create blank rows between two lines of text for example.
 */
- (void)addPaddedLine;

/*!
 * Clear out any formatted text the formatter is currently holding and set it to the 
 * empty string @""
 */
- (void)clearString;

@end
