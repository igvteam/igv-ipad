// 
// The MIT License (MIT)
// 
// 
// Copyright (c) 2014 Broad Institute
// 
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


//
// Created by jrobinso on 7/27/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "IndexFactory.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "NSData+GZIP.h"
#import "LittleEndianByteBuffer.h"
#import "LinearIndex.h"

@implementation IndexFactory

+ (id)indexFromData:(NSData *)aData pathExtension:(NSString *)pathExtension {

    NSData *data = aData;
    if ([pathExtension isEqualToString:@"gz"]) {

//        data = [NSData dataWithGzippedData:aData];
        data = [aData gunzippedData];
    }

    LittleEndianByteBuffer *les = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    // Read the type and version,  then create the appropriate type
    [les nextInt];    // int magicNumber =
    int type = [les nextInt];

    if (type == 1) {

        // Linear
       return [LinearIndex indexFromBytes:les withError:nil];
    } else if (type == 2) {

        // Interval tree
        // TODO -- error

    } else if (type == 3) {

        //Tabix
        // TODO -- error
    } else {

        // unknown
        // TODO -- error
    }

    return nil;

}

+ (id) indexFromFile:(NSString *)indexFile withError:(NSError **)error {

    HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:indexFile];
    if (nil == response) {
        return nil;
    }

    // TODO -- check for errors
    NSData *data = response.receivedData;
    if ([[indexFile pathExtension] isEqualToString:@"gz"]) {
        data = [response.receivedData gunzippedData];
    }

    LittleEndianByteBuffer *les = [LittleEndianByteBuffer littleEndianByteBufferWithData:data];

    // Read the type and version,  then create the appropriate type
    [les nextInt];    // int magicNumber =
    int type = [les nextInt];

    if (type == 1) {
        // Linear
       return [LinearIndex indexFromBytes: les withError: error];
    } else if (type == 2) {
        // Interval tree
        // TODO -- error

    }
    else if (type == 3) {
        //Tabix
        // TODO -- error
    }
    else {
        // unknown
        // TODO -- error
    }
    return nil;
}



@end