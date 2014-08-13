//
//  CBLQueryPlannerTests.m
//  Tunes
//
//  Created by Jens Alfke on 8/12/14.
//  Copyright (c) 2014 CouchBase, Inc. All rights reserved.
//

#import "CBLQueryPlanner+Private.h"
#import "Test.h"


#if DEBUG


// compact description of an object using "[a, b...]" for arrays and single-quoting strings.
static NSString* desc(id obj) {
    if ([obj isKindOfClass: [NSArray class]]) {
        NSMutableString* result = [@"[" mutableCopy];
        BOOL first = YES;
        for (id item in obj) {
            if (first)
                first = NO;
            else
                [result appendString: @", "];
            [result appendString: desc(item)];
        }
        [result appendString: @"]"];
        return result;
    } else if ([obj isKindOfClass: [NSString class]]) {
        return [NSString stringWithFormat: @"'%@'", obj];
    } else {
        return [obj description];
    }
}


// Checks whether desc(value) matches expectedDesc.
static BOOL matchDesc(NSString* what, id value, NSString* expectedDesc) {
    if([desc(value) isEqualToString: expectedDesc] || (!value && !expectedDesc))
        return YES;
    Log(@"  **EXPECTED %@", expectedDesc);
    return NO;
}


static void test(NSArray* select,
                 NSString* where,
                 NSString* orderKey,
                 NSString* expectedMapPred,
                 NSString* expectedKeyExprs,
                 NSString* expectedValues,
                 NSString* expectedStartKey,
                 NSString* expectedEndKey,
                 NSString* expectedSorts,
                 NSString* expectedFilter)
{
    NSPredicate* wherePred = [NSPredicate predicateWithFormat: where];
    NSArray* orderBy = nil;
    if (orderKey)
        orderBy = @[[NSSortDescriptor sortDescriptorWithKey: orderKey ascending: YES]];
    Log(@"--------------");
    Log(@"Select: %@", desc(select));
    Log(@"Where:  %@", wherePred);
    Log(@"Order:  %@", orderKey);
    NSError* error;
    CBLQueryPlanner* planner = [[CBLQueryPlanner alloc]
                initWithView: nil
                select: select
                where: [NSPredicate predicateWithFormat: where]
                orderBy: orderBy
                error: &error];
    NSCAssert(planner, @"Couldn't create planner: %@", error);
    BOOL result = YES;
    Log(@"Map pred --> %@", planner.mapPredicate);
    result = matchDesc(@"mapPredicate", planner.mapPredicate, expectedMapPred) && result;
    Log(@"Key expr --> %@", desc(planner.keyExpressions));
    result = matchDesc(@"keyExpressions", planner.keyExpressions, expectedKeyExprs) && result;
    Log(@"Value -->    %@", desc(planner.valueTemplate));
    result = matchDesc(@"valueTemplate", planner.valueTemplate, expectedValues) && result;
    Log(@"StartKey --> %@", desc(planner.queryStartKey));
    result = matchDesc(@"queryStartKey", planner.queryStartKey, expectedStartKey) && result;
    Log(@"EndKey -->   %@", desc(planner.queryEndKey));
    result = matchDesc(@"queryEndKey", planner.queryEndKey, expectedEndKey) && result;
    Log(@"Sort -->     %@", desc(planner.sortDescriptors));
    result = matchDesc(@"sortDescriptors", planner.sortDescriptors, expectedSorts) && result;
    Log(@"Filter -->   %@", planner.filter);
    result = matchDesc(@"filter", planner.filter, expectedFilter) && result;

    NSCAssert(result, @"Incorrect query plan");
    Log(@"**OK**");
}


TestCase(CBLQueryPlanner) {
    test(/*select*/ @[@"title", @"body", @"author", @"date"],
         /*where*/ @"type == 'post' and title beginswith $PREFIX and tags contains $TAG",
         /*order by*/ @"date",
         @"type == \"post\"",
         @"[tags, title]",
         @"['body', 'author', 'date']",
         @"{$TAG, $PREFIX}",
         @"{$TAG, $PREFIX}",
         @"[(value2, ascending, compare:)]",
         nil);

    test(/*select*/ @[@"title", @"body", @"author", @"date"],
         /*where*/ @"type == 'post' and tags contains $TAG",
         /*order by*/ nil,
         @"type == \"post\"",
         @"[tags]",
         @"['title', 'body', 'author', 'date']",
         @"$TAG",
         @"$TAG",
         nil,
         nil);

    test(/*select*/ @[@"title", @"body", @"author", @"date"],
         /*where*/ @"type == 'post' and tags contains $TAG",
         /*order by*/ @"date",
         @"type == \"post\"",
         @"[tags, date]",
         @"['title', 'body', 'author']",
         @"{$TAG}",
         @"{$TAG}",
         nil,
         nil);
    
    test(/*select*/ @[@"body", @"author", @"date"],
         /*where*/ @"type == 'comment' and post_id == $POST_ID",
         /*order by*/ @"date",
         @"type == \"comment\"",
         @"[post_id, date]",
         @"['body', 'author']",
         @"{$POST_ID}",
         @"{$POST_ID}",
         nil,
         nil);

    test(/*select*/ @[@"wingspan", @"name"],
         /*where*/ @"type == 'bird'",
         /*order by*/ @"name",
         @"type == \"bird\"",
         @"[name]",
         @"['wingspan']",
         nil, // there's no startKey or endKey because we didn't specify a range.
         nil,
         nil,
         nil);

    test(/*select*/ @[@"Album"],
         /*where*/ @"TotalTime / 1000.0 between {$MIN, $MAX} and Artist = $A and Name contains $NAME",
         /*order by*/ @"Name",
         nil,
         @"[Artist, TotalTime / 1000]",
         @"['Album', 'Name']",
         @"{$A, $MIN}",
         @"{$A, $MAX}",
         @"[(value1, ascending, compare:)]",
         @"value1 CONTAINS $NAME");

    test(/*select*/ @[@"Album"],
         /*where*/ @"Time >= $MIN and Time <= $MAX and Artist = $A and Name contains $NAME",
         /*order by*/ @"Name",
         nil,
         @"[Artist, Time]",
         @"['Album', 'Name']",
         @"{$A, $MIN}",
         @"{$A, $MAX}",
         @"[(value1, ascending, compare:)]",
         @"value1 CONTAINS $NAME");
}


#endif // DEBUG
