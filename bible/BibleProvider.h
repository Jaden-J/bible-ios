//
//  BibleProvider.h
//  bible
//
//  Created by Thom on 14-4-15.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define QUERY_CHAPTER "select reference_osis, reference_human, content, previous_reference_osis, next_reference_osis\
    from chapters where reference_osis = ? or reference_osis = ? order by reference_osis desc limit 1"
#define QUERY_METADATA "select name, value from metadata"
#define QUERY_CHAPTERS "select reference_osis from chapters where reference_osis like ?"
#define QUERY_BOOKS "select osis, human from books"

@interface BibleProvider : NSObject

@property(nonatomic, copy) NSString* book;
@property(nonatomic, copy) NSString* osis;
@property(nonatomic, copy) NSString* chapter;
@property(nonatomic, copy) NSString* content;
@property(nonatomic, copy) NSString* version;
@property(nonatomic, getter = getChapters) NSArray* chapters;
@property(nonatomic, getter = getBooks) NSArray* books;

@property(nonatomic, copy) NSArray* versions;

+ (id)defaultProvider;

- (BOOL)changeVersion:(NSString *)newVersion;

- (BOOL)changeOSIS:(NSString *)newOSIS;

- (BOOL)next;

- (BOOL)previous;

- (NSString *)getVersionFullName:(NSString *)versionName;

- (NSString *)getVersionShortName:(NSString *)versionName;

- (NSString *)getChapterName:(NSString *)chapterName;

- (NSString *)getBookName:(NSString *)osisName;

- (BOOL)changeBook:(NSString *)newBook;

- (void)saveOSISVersion;

@end
