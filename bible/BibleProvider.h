//
//  BibleProvider.h
//  bible
//
//  Created by Thom on 14-4-15.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define QUERY_CHAPTER "select reference_osis, content, previous_reference_osis, next_reference_osis\
    from chapters where reference_osis = ? or reference_osis = ? order by reference_osis desc limit 1"
#define QUERY_METADATA "select name, value from metadata"
#define QUERY_CHAPTERS "select reference_osis from chapters where reference_osis like ?"
#define QUERY_BOOKS "select osis, human from books"
#define QUERY_ANNOTATIONS "select link, content from annotations where osis = ?"

@interface BibleProvider : NSObject

@property(nonatomic, readonly, copy) NSString* chapter;
@property(nonatomic, readonly, copy) NSString* content;
@property(nonatomic, readonly, copy) NSString* version;
@property(nonatomic, readonly, copy) NSArray* versions;
@property(nonatomic, readonly, getter = getBooks) NSArray* books;
@property(nonatomic, readonly, getter = getChapters) NSArray* chapters;

@property(nonatomic) NSString *selected;
@property(nonatomic) NSString *verse;


+ (id)defaultProvider;

- (BOOL)setChapter:(NSString *)newChapter;

- (BOOL)setBook:(NSString *)newBook;

- (BOOL)setVersion:(NSString *)newVersion;

- (BOOL)nextChapter;

- (BOOL)previousChapter;

- (NSString *)getVersionFullName:(NSString *)versionName;

- (NSString *)getVersionShortName:(NSString *)versionName;

- (NSString *)getBookName:(NSString *)chapter;

- (NSString *)getChapterName:(NSString *)chapter;

- (void)save;

- (NSString *)getAnnotation:(NSString *)link;

- (BOOL)refreshVersions;

@end
