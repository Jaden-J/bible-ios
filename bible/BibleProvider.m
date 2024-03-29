//
//  BibleProvider.m
//  bible
//
//  Created by Thom on 14-4-15.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import "BibleProvider.h"

@implementation BibleProvider {
    sqlite3* database;
    NSString* reading;
    NSString* version;
    NSString* language;
    BOOL isZhHans;
    NSFileManager *fileManager;
    NSUserDefaults *userDefaults;

    NSString *osis;
    NSString *content;
    NSString *prevOSIS;
    NSString *nextOSIS;

    NSMutableArray *versions;
    NSMutableArray *chapters;
    NSMutableArray *books;
    NSMutableDictionary *bookNames;
    NSMutableDictionary *annotations;

    NSString *bibledata;
    NSMutableDictionary *metadatas;

    NSString *_selected;
    NSString *_verse;
}

@synthesize chapter = osis;
@synthesize content = content;
@synthesize version = version;
@synthesize versions = versions;
@synthesize chapters = chapters;
@synthesize books = books;

- (id)init
{
    if ((self = [super init])) {
        database = nil;

        versions = [NSMutableArray arrayWithCapacity:5];
        chapters = [NSMutableArray arrayWithCapacity:150];
        books = [NSMutableArray arrayWithCapacity:66];
        bookNames = [NSMutableDictionary dictionaryWithCapacity:66];
        annotations = [NSMutableDictionary dictionary];

        bibledata = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"reading" ofType:@"html"];
        reading = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

        fileManager = [NSFileManager defaultManager];
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        isZhHans = [language isEqualToString:@"zh-Hans"];
        metadatas = [NSMutableDictionary dictionaryWithCapacity:5];

        userDefaults = [NSUserDefaults standardUserDefaults];

        NSString *defaultVersion = [userDefaults stringForKey:@"version"];
        if (defaultVersion == nil || [defaultVersion length] == 0) {
            defaultVersion = NSLocalizedString(@"niv1984", @"Demo Version Name, only support niv1984, cunpss, cunpts");
        }
        NSString *defaultOSISVerse = [userDefaults stringForKey:@"osis"];
        if (defaultOSISVerse == nil || [defaultVersion length] == 0) {
            defaultOSISVerse = @"Gen.int";
        }
        [self setVersion:defaultVersion];
        [self setChapter:defaultOSISVerse];
        [self refreshVersions];
    }
    return self;
}

+ (id)defaultProvider
{
    static id instance = nil;
    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (BOOL)setVersion:(NSString *)newVersion
{
    NSString *path;
    sqlite3 *newDatabase;
    if (newVersion == nil || [newVersion isEqualToString:version]) {
        return NO;
    }
    path = [self getPath:newVersion];
    if (path == nil) {
        return NO;
    }
    if (sqlite3_open([path UTF8String], &newDatabase) == SQLITE_OK) {
        if (database != nil) {
            sqlite3_close(database);
        }
        version = newVersion;
        database = newDatabase;
        [self reloadOSIS];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)reloadOSIS
{
    if (chapters != nil) {
        [chapters removeAllObjects];
        [self getChapters];
    }
    if (books != nil) {
        [books removeAllObjects];
        [self getBooks];
    }
    if (osis != nil) {
        NSString *newOSIS = osis;
        osis = nil;
        if (![self loadChapter:newOSIS]) {
            return [self loadChapter:@"Gen.int"];
        } else {
            return NO;
        }
    }
    return NO;
}

- (BOOL)loadChapter:(NSString *)newOSIS
{
    BOOL OSISChanged = NO;
    if (database == nil) {
        return OSISChanged;
    }
    if (newOSIS == nil) {
        newOSIS = @"Gen.int";
    }
    if ([newOSIS isEqualToString:osis]) {
        return OSISChanged;
    }
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, (const char *) QUERY_CHAPTER, -1, &statement, nil) != SQLITE_OK) {
        return OSISChanged;
    }
    NSString *noIntOSIS = [newOSIS stringByReplacingOccurrencesOfString:@"int" withString:@"1"];
    sqlite3_bind_text(statement, 1, [newOSIS UTF8String], -1, NULL);
    sqlite3_bind_text(statement, 2, [noIntOSIS UTF8String], -1, NULL);
    if (sqlite3_step(statement) == SQLITE_ROW) {
        content = [self getString:statement andIndex:1];
        if (isZhHans || [version isEqualToString:@"ccb"] || [version hasSuffix:@"ss"]) {
            content = [content stringByReplacingOccurrencesOfString:@"「" withString:@"“"];
            content = [content stringByReplacingOccurrencesOfString:@"」" withString:@"”"];
            content = [content stringByReplacingOccurrencesOfString:@"『" withString:@"‘"];
            content = [content stringByReplacingOccurrencesOfString:@"』" withString:@"’"];
            content = [content stringByReplacingOccurrencesOfString:@"上帝" withString:@"　神"];
        }
        content = [NSString stringWithFormat:reading, _verse, _selected, osis, content];
        osis = [self getString:statement andIndex:0];
        prevOSIS = [self getString:statement andIndex:2];
        nextOSIS = [self getString:statement andIndex:3];
        OSISChanged = YES;
    }
    sqlite3_finalize(statement);
    [annotations removeAllObjects];
    if (sqlite3_prepare_v2(database, (const char *) QUERY_ANNOTATIONS, -1, &statement, nil) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [osis UTF8String], -1, NULL);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *key = [self getString:statement andIndex:0];
            NSString *value = [self getString:statement andIndex:1];
            [annotations setObject:value forKey:key];
        }
        sqlite3_finalize(statement);
    }
    return OSISChanged;
}

- (BOOL)setChapter:(NSString *)newOSISVerse
{
    NSString *newOSIS;
    if ([newOSISVerse rangeOfString:@":"].location != NSNotFound) {
        NSArray *osisVerse = [newOSISVerse componentsSeparatedByString:@":"];
        newOSIS = osisVerse[0];
        _verse = osisVerse[osisVerse.count - 1];
    } else {
        newOSIS = newOSISVerse;
        _verse = @"-1";
    }
    _selected = @"";
    return [self loadChapter:newOSIS];
}

- (NSString*)getString:(sqlite3_stmt *)statement andIndex:(int)index
{
    const char *text = (const char *) sqlite3_column_text(statement, index);
    if (text == NULL) {
        return @"";
    } else {
        return [NSString stringWithUTF8String:text];
    }
}

- (BOOL)nextChapter
{
    return [self setChapter:nextOSIS];
}

- (BOOL)previousChapter
{
    return [self setChapter:prevOSIS];
}

- (BOOL)refreshVersions
{
    BOOL directory;
    if (![fileManager fileExistsAtPath:bibledata isDirectory:&directory]) {
        [fileManager createDirectoryAtPath:bibledata withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [versions removeAllObjects];
    if (!directory) {
        [fileManager removeItemAtPath:bibledata error:nil];
    } else {
        for (NSString *path in [fileManager contentsOfDirectoryAtPath:bibledata error:nil]) {
            if ([path hasSuffix:@".sqlite3"]) {
                [versions addObject:[path stringByReplacingOccurrencesOfString:@".sqlite3" withString:@""]];
            }
        }
    }
    if ([versions count] == 0) {
        [versions addObject:@"cunpss"];
        [versions addObject:@"cunpts"];
        [versions addObject:@"niv1984"];
    }
    return YES;
}

- (NSString *)getPath:(NSString *)versionName
{
    NSString *path = [[bibledata stringByAppendingPathComponent:versionName] stringByAppendingString:@".sqlite3"];
    if ([fileManager fileExistsAtPath:path]) {
        return path;
    }
    path = [[NSBundle mainBundle] pathForResource:versionName ofType:@"sqlite3"];
    if ([fileManager fileExistsAtPath:path]) {
        return path;
    }
    return nil;
}

- (NSMutableDictionary *)loadVersionMeta:(NSString *)versionName
{
    sqlite3 *meta;
    NSString *path = [self getPath:versionName];
    NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithCapacity:5];
    if (path != nil && sqlite3_open([path UTF8String], &meta) == SQLITE_OK) {
        sqlite3_stmt *stmt;
        sqlite3_prepare_v2(meta, (const char *) QUERY_METADATA, -1, &stmt, nil);
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString *name = [self getString:stmt andIndex:0];
            NSString *value = [self getString:stmt andIndex:1];
            if ([name length] > 0) {
                [metadata setObject:value forKey:name];
            }
        }
        sqlite3_finalize(stmt);
        sqlite3_close(meta);
    }
    [metadatas setObject:metadata forKey:versionName];
    return metadata;
}

- (NSString *)getVersionMetadata:(NSString *)versionName withName:(NSString *)name defaultValue:(NSString *)value
{
    NSUInteger index = [versions indexOfObject:versionName];
    if (index > [versions count]) {
        return value;
    }
    NSMutableDictionary* metadata = [metadatas objectForKey:versionName];
    if (metadata == nil) {
        metadata = [self loadVersionMeta:versionName];
    }
    NSString *v = [metadata objectForKey:name];
    if (v == nil) {
        return value;
    } else {
        return v;
    }
}

- (NSString *)getVersionFullName:(NSString *)versionName
{
    return [self getVersionMetadata:versionName withName:@"fullname" defaultValue:[versionName uppercaseString]];
}

- (NSString *)getVersionShortName:(NSString *)versionName
{
    return [self getVersionMetadata:versionName withName:@"name" defaultValue:[versionName uppercaseString]];
}

- (NSArray *)getChapters
{
    NSString *book = [[osis componentsSeparatedByString:@"."] firstObject];
    if ([chapters count] == 0 || ![[chapters objectAtIndex:0] hasPrefix:[book stringByAppendingString:@"."]]) {
        [chapters removeAllObjects];
        sqlite3_stmt *statement;
        sqlite3_prepare_v2(database, (const char *) QUERY_CHAPTERS, -1, &statement, nil);
        sqlite3_bind_text(statement, 1, [[book stringByAppendingString:@".%"] UTF8String], -1, NULL);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            [chapters addObject:[self getString:statement andIndex:0]];
        }
        sqlite3_finalize(statement);
    }
    return chapters;
}

- (NSArray *)getBooks
{
    if ([books count] == 0) {
        [books removeAllObjects];
        [bookNames removeAllObjects];
        sqlite3_stmt *statement;
        sqlite3_prepare_v2(database, (const char *) QUERY_BOOKS, -1, &statement, nil);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *book = [self getString:statement andIndex:0];
            NSString *bookName = [self getString:statement andIndex:1];
            [books addObject:book];
            [bookNames setObject:bookName forKey:book];
        }
        sqlite3_finalize(statement);
    }
    return books;
}

- (NSString *)getBookName:(NSString *)chapter
{
    NSString *book = [[chapter componentsSeparatedByString:@"." ] firstObject];
    NSString *bookName = [bookNames objectForKey:book];
    if (bookName == nil) {
        return book;
    } else {
        return bookName;
    }
}

- (NSString *)getChapterName:(NSString *)chapter
{
    NSString *chapterName = [[chapter componentsSeparatedByString:@"." ] lastObject];
    if ([@"int" isEqualToString:chapterName]) {
        return NSLocalizedString(@"Intro", @"Chapter Introduction in some bible translations");
    } else {
        return chapterName;
    }
}

- (BOOL)setBook:(NSString *)newBook
{
    NSString *oldBook = [[osis componentsSeparatedByString:@"."] firstObject];
    if ([oldBook isEqualToString:newBook]) {
        return NO;
    } else {
        if (oldBook != nil) {
            [userDefaults setObject:[osis stringByAppendingFormat:@":%@", _verse] forKey:oldBook];
            [userDefaults synchronize];
        }
        NSString *newOSISVerse = [userDefaults stringForKey:newBook];
        if (newOSISVerse == nil || [newOSISVerse length] == 0) {
            newOSISVerse = [newBook stringByAppendingString:@".int"];
        }
        return [self setChapter:newOSISVerse];
    }
}

- (void)save
{
    [userDefaults setObject:[osis stringByAppendingFormat:@":%@", _verse] forKey:@"osis"];
    [userDefaults setObject:version forKey:@"version"];
    [userDefaults synchronize];
}

- (NSString *)getAnnotation:(NSString *)link
{
    return [annotations objectForKey:link];
}

- (void)dealloc
{
    if (database != nil) {
        sqlite3_close(database);
    }
}

@end
