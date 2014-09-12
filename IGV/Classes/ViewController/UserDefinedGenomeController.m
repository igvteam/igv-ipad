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
//  UserDefinedGenomeController.m
//  IGV
//
//  Created by turner on 5/27/14.
//
//

#import "UserDefinedGenomeController.h"
#import "Logging.h"
#import "GenomeManager.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "IGVHelpful.h"

@interface UserDefinedGenomeController ()
@property(nonatomic, retain) IBOutlet UITextField *genomeNameTextField;
@property(nonatomic, retain) IBOutlet UITextField *fastaPathTextField;
@property(nonatomic, retain) IBOutlet UITextField *cytobandPathTextField;
@property(nonatomic, retain) IBOutlet UITextField *referenceGenePathTextField;

- (NSDictionary *)userDefinedGenomeWithGenomeName:(NSString *)genomeName
                                fastaSequenceFile:(NSString *)fastaSequenceFile
                                     cytobandFile:(NSString *)cytobandFile
                                         geneFile:(NSString *)geneFile;
@end

@implementation UserDefinedGenomeController

@synthesize genomeNameTextField = _genomeNameTextField;
@synthesize fastaPathTextField = _fastaPathTextField;
@synthesize cytobandPathTextField = _cytobandPathTextField;
@synthesize referenceGenePathTextField = _referenceGenePathTextField;
@synthesize userDefinedGenome = _userDefinedGenome;

- (void)dealloc {
    
    self.genomeNameTextField = nil;
    self.fastaPathTextField = nil;
    self.cytobandPathTextField = nil;
    self.referenceGenePathTextField = nil;
    self.userDefinedGenome = nil;

    [super dealloc];
}

- (NSDictionary *)userDefinedGenomeWithGenomeName:(NSString *)genomeName
                                fastaSequenceFile:(NSString *)fastaSequenceFile
                                     cytobandFile:(NSString *)cytobandFile
                                         geneFile:(NSString *)geneFile {


    if ((nil == fastaSequenceFile || [@"" isEqualToString:fastaSequenceFile])) {
        return nil;
    }

    if (![IGVHelpful isReachablePath:fastaSequenceFile]) {
        return nil;
    }

    if (nil == genomeName || [@"" isEqualToString:genomeName]) {

        NSArray *parts = [fastaSequenceFile componentsSeparatedByString:@"/"];
        NSString *filename = [parts objectAtIndex:([parts count] - 1)];

        genomeName = filename;
    }

    NSMutableDictionary *userDefinedGenome = [NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionary] forKey:genomeName];
    NSArray *keys = [NSArray arrayWithObjects:kFastaSequenceFileKey, kCytobandFileKey, kGeneFileKey, nil];
    NSArray *objs = [NSArray arrayWithObjects: fastaSequenceFile,     cytobandFile,     geneFile,    nil];
    for (NSString *obj in objs) {

        if (obj && ![@"" isEqualToString:obj]) {

            [[userDefinedGenome objectForKey:genomeName] setObject:obj forKey:[keys objectAtIndex:[objs indexOfObject:obj]]];
        }
    }

    return userDefinedGenome;
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self performSegueWithIdentifier:@"UnwindUserDefinedGenomeControllerWithSave" sender:self];
    return YES;
}

#pragma mark - UIStoryboardSegue Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    ALog(@"seque %@ destination %@", segue.identifier, segue.destinationViewController);

    self.userDefinedGenome = [self userDefinedGenomeWithGenomeName:self.genomeNameTextField.text
                                                 fastaSequenceFile:self.fastaPathTextField.text
                                                      cytobandFile:self.cytobandPathTextField.text
                                                          geneFile:self.referenceGenePathTextField.text];

}

@end
