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

    NSString *osis;
    NSString *book;
    NSString *chapter;
    NSString *content;
    NSString *prevOSIS;
    NSString *nextOSIS;
    NSMutableArray *chapters;

    NSArray *versions;
    NSString *bibledata;
    NSMutableDictionary *metadatas;
}

@synthesize book = book;
@synthesize osis = osis;
@synthesize chapter = chapter;
@synthesize content = content;
@synthesize version = version;
@synthesize versions = versions;
@synthesize chapters = chapters;

- (id)init
{
    if ((self = [super init])) {
        version = nil;
        database = nil;

        chapters = [NSMutableArray arrayWithCapacity:20];
        bibledata = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)
                      objectAtIndex:0] stringByAppendingPathComponent:@"bibledata"];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"reading" ofType:@"html"];
        reading = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

        fileManager = [NSFileManager defaultManager];
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        isZhHans = [language isEqualToString:@"zh-Hans"];
        metadatas = [NSMutableDictionary dictionaryWithCapacity:5];

        // TODO: store version and osis
        [self changeVersion:NSLocalizedString(@"niv1984", @"Demo Version Name, only support niv1984, cunpss, cunpts")];
        [self changeOSIS:@"Gen.1"];
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

- (BOOL)changeVersion:(NSString *)newVersion
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
    }
    if (osis != nil) {
        NSString *newOSIS = osis;
        osis = nil;
        if (![self changeOSIS:newOSIS]) {
            return [self changeOSIS:@"Gen.1"];
        } else {
            return NO;
        }
    }
    return NO;
}

- (BOOL)changeOSIS:(NSString *)newOSIS
{
    BOOL OSISChanged = NO;
    if (database == nil) {
        return OSISChanged;
    }
    if (newOSIS == nil) {
        newOSIS = @"Gen.1";
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
        osis = [self getString:statement andIndex:0];
        book = [self getString:statement andIndex:1];
        content = [self getString:statement andIndex:2];
        if (isZhHans || [version isEqualToString:@"ccb"] || [version hasSuffix:@"ss"]) {
            content = [content stringByReplacingOccurrencesOfString:@"「" withString:@"“"];
            content = [content stringByReplacingOccurrencesOfString:@"」" withString:@"”"];
            content = [content stringByReplacingOccurrencesOfString:@"『" withString:@"』"];
            content = [content stringByReplacingOccurrencesOfString:@"』" withString:@"’"];
        }
        content = [NSString stringWithFormat:reading, osis, content];
        prevOSIS = [self getString:statement andIndex:3];
        nextOSIS = [self getString:statement andIndex:4];
        chapter = [[osis componentsSeparatedByString:@"."] lastObject];
        OSISChanged = YES;
    }
    sqlite3_finalize(statement);
    return OSISChanged;
}

- (NSString*)getString:(sqlite3_stmt *)statement andIndex:(int)index
{
    const char *text = (const char *) sqlite3_column_text(statement, index);
    if (text == NULL) {
        return @"";
    } else {
        return [[NSString alloc] initWithUTF8String:text];
    }
}

- (BOOL)next
{
    return [self changeOSIS:nextOSIS];
}

- (BOOL)previous
{
    return [self changeOSIS:prevOSIS];
}

- (BOOL)refreshVersions
{
    BOOL directory;
    if (![fileManager fileExistsAtPath:bibledata isDirectory:&directory]) {
        [fileManager createDirectoryAtPath:bibledata withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSURL fileURLWithPath:bibledata] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    if (!directory) {
        versions = nil;
        [fileManager removeItemAtPath:bibledata error:nil];
    } else {
        versions = [fileManager contentsOfDirectoryAtPath:bibledata error:nil];
    }
    if (versions == nil || [versions count] == 0) {
        versions = [NSArray arrayWithObjects:@"cunpss", @"cunpts", @"niv1984", nil];
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
    int index = [versions indexOfObject:versionName];
    if (index < 0) {
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
    NSString *osisBook = [[osis componentsSeparatedByString:@"."] firstObject];
    if ([chapters count] == 0 || ![[chapters objectAtIndex:0] hasPrefix:[osisBook stringByAppendingString:@"."]]) {
        [chapters removeAllObjects];
        sqlite3_stmt *statement;
        sqlite3_prepare_v2(database, (const char *) QUERY_CHAPTERS, -1, &statement, nil);
        sqlite3_bind_text(statement, 1, [[osisBook stringByAppendingString:@".%"] UTF8String], -1, NULL);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            [chapters addObject:[self getString:statement andIndex:0]];
        }
        sqlite3_finalize(statement);
    }
    return chapters;
}

- (NSString *)getChapterName:(NSString *)chapterName
{
    NSString *name = [[chapterName componentsSeparatedByString:@"." ] lastObject];
    if ([@"int" isEqualToString:name]) {
        return NSLocalizedString(@"Intro", @"Chapter Introduction in some bible translations");
    } else {
        return name;
    }
}
- (void)dealloc
{
    if (database != nil) {
        sqlite3_close(database);
    }
}

@end
