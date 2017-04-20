//
//  PuzzleView.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/6/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "PuzzleView.h"

@implementation PuzzleView

-(id)initWithGameObject:(GameObject *)gameObject andFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.frame = frame;
        self.puzzle = gameObject.puzzle; // assign the private property so that it can be accessed on all methods.
        self.game = gameObject;
        
        // timer creation and start
        self.timerLabel = [UILabel new];
        self.timerLabel.frame = CGRectMake(self.frame.size.width / 2 - 10, 1, 160.0, 40.0);
        self.timerLabel.textColor = [self colorWithHexString:@"71C7F0"];
        [self addSubview:self.timerLabel];
        
        // create the actual puzzle that the user interacts with
        if (self.puzzle.puzzleImage.size.height > self.puzzle.puzzleImage.size.width) { // if the image is portrait, create a portrait puzzle
            [self createVerticalPuzzleWithGridSize:[self.puzzle getNumberOfPieces]];
            //NSLog(@"portrait puzzle");
        }
        
        else if (self.puzzle.puzzleImage.size.width == self.puzzle.puzzleImage.size.height) { // if the image is landscape, create a landscape puzzle
            [self createSquarePuzzleWithGridSize:[self.puzzle getNumberOfPieces]];
            //NSLog(@"square puzzle");
        }
    }
    
    return self;
}

# pragma mark - view methods

// create a target view
-(void)createVerticalTargetViewInRect:(CGRect)targetRect WithImage:(UIImage *)image num:(NSInteger)pieceNum sideLenX:(CGFloat)sideLengthX sideLenY:(CGFloat)sideLengthY {
    int count = 0; // count the id of each target
    CGFloat x = targetRect.origin.x;
    CGFloat y = targetRect.origin.y;
    y = 30; // give some space for the timer label
    // NSLog(@"x : %f    y : %f", x, y);
    NSInteger col = sqrt(pieceNum); // calculate the column number
    NSInteger row = sqrt(pieceNum); // calculate the row number
    for (int i = 0; i < row; i++) {
        x = targetRect.origin.x; // restart each new row (start leftmost)
        for (int j = 0; j < col; j++) {
            TargetView* target = [[TargetView alloc]initWithFrame:CGRectMake(x, y, sideLengthX, sideLengthY)]; // initialize each target with the current x & y and static sideLengthX & sideLengthY
            target.backgroundColor = [self colorWithHexString:@"71C7F0"]; // blue
            target.targetId = count;
            [self addSubview:target]; // add to the PuzzleView's subview
            [self.puzzle.targets addObject:target]; // add the current target to the puzzle's target array
            count++;
            // NSLog(@"x : %f    y : %f", x, y);
            x = x + sideLengthX; // add a target view's X length each time the column loop is traversed
            
            if (j == (col - 1) && i == 0) { // if the last column of the first row is being created, put a pause button there
                self.pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.pauseButton addTarget:self
                                     action:@selector(pauseButtonDidPress:)
                           forControlEvents:UIControlEventTouchUpInside];
                [self.pauseButton setImage:[UIImage imageNamed:@"pause-button"] forState:UIControlStateNormal];
                UIFont *myFont = [UIFont fontWithName: @"Avenir Next" size: 18.0 ];
                self.pauseButton.titleLabel.font = myFont;
                [self.pauseButton setTitleColor:[self colorWithHexString:@"71C7F0"] forState:UIControlStateNormal];
                self.pauseButton.frame = CGRectMake(self.frame.size.width - 100, 5, 25.0, 25.0);
                self.pauseButton.adjustsImageWhenHighlighted = YES;
                [self addSubview:self.pauseButton];
            }
        }
        // NSLog(@"x : %f    y : %f", x, y);
        y = y + sideLengthY; // add a target view's Y length each time the row loop is traversed
    }
}

// create a piece view
-(void)createVerticalPieceViewInRect:(CGRect)pieceRect WithImage:(UIImage *)image num:(NSInteger)pieceNum sideLenX:(CGFloat)sideLengthX sideLenY:(CGFloat)sideLengthY {
    // init a mutableArray with integer from 0 to pieceNum-1
    NSMutableArray* idArray = [[NSMutableArray alloc]initWithCapacity:pieceNum];
    for (int i = 0; i < pieceNum; i++) {
        NSNumber* iWrapped = [NSNumber numberWithInt:i];
        [idArray addObject:iWrapped];
    }
    NSMutableArray* images = [self splitImageWith:image andPieceNum:pieceNum]; // create all of the pieces by slicing the image.
    CGFloat x = pieceRect.origin.x;
    CGFloat y = pieceRect.origin.y;
    y = 30;
    NSInteger col = sqrt(pieceNum); // calculate the column number
    NSInteger row = sqrt(pieceNum); // calculate the row number
    for (int i = 0; i < row; i++) {
        x = pieceRect.origin.x; // restart each new row (start leftmost)
        for (int j = 0; j < col; j++) {
            PieceView* piece = [[PieceView alloc]initWithFrame:CGRectMake(x, y, sideLengthX, sideLengthY)];
            piece.dragDelegate = self;
            int randomIndex = arc4random()%([idArray count]); // create random index
            piece.pieceId = [idArray[randomIndex] intValue]; // assign random index to piece
            piece.image = images[piece.pieceId];
            [idArray removeObjectAtIndex:randomIndex]; // remove the object after using so the random index is not reused
            
            // this code here is to match each piece with the target it is centered on top of
            for (TargetView* currentTargetView in self.puzzle.targets) { // self.targets is the array of TargetViews
                if (CGRectContainsPoint(currentTargetView.frame, piece.center)) {
                    piece.targetView = currentTargetView; // assign the target view
                    if (piece.pieceId == piece.targetView.targetId) { // check if piece is matched to its target
                        piece.isMatched = true; // if matched at beginning, set it to true
                        piece.userInteractionEnabled = false;
                    }
                    else if (piece.pieceId != piece.targetView.targetId) {
                        piece.isMatched = false; // if it's not matched at beginning, set it to false
                        piece.layer.borderWidth = 4.0f;
                        piece.layer.borderColor = [self colorWithHexString:@"71C7F0"].CGColor;
                    }
                }
            }
            [self addSubview:piece];
            [self.puzzle.pieces addObject:piece];
            x = x + sideLengthX;
        }
        y = y + sideLengthY;
    }
}

# pragma mark - puzzle methods logic

-(void)createVerticalPuzzleWithGridSize:(NSInteger)size {
    if (self.puzzle.puzzleImage) { // if the image from the preview controller was assigned to this
        NSLog(@"Puzzle Image Width: %f     Puzzle Image Height: %f", self.puzzle.puzzleImage.size.width, self.puzzle.puzzleImage.size.height);
        
        CGFloat sideLengthY = self.puzzle.puzzleImage.size.height/sqrt(self.puzzle.numberofPieces); // sideLengthY is the length of each PieceView/TargetView. Formula: length of photo (or height) divided by # of pieces in Y-axis = sideLengthY (if we want not X by X we need two pieceNums?********** like 7x4. REMEMBER THIS.)
        CGFloat sideLengthX = self.puzzle.puzzleImage.size.width/sqrt(self.puzzle.numberofPieces); // sideLengthX is the width of each PieceView/TargetView. Formula: width of photo (or height) divided by # of pieces in X-axis = sideLengthX
        // NSLog(@"sideLengthY: %f     sideLengthX: %f", sideLengthY, sideLengthX);
        
        CGRect targetRect;
        CGRect pieceRect;
    
        // this is the place of the very first target view.
        targetRect = CGRectMake(0, 0, 200, 200); // 200s do nothing, just placeholders
        
        // this is the place of the very first piece view.
        pieceRect = CGRectMake(0, 0, 200, 200); // 200s do nothing, just placeholders
        
        
        // create all of the target views of the puzzle
        [self createVerticalTargetViewInRect:targetRect WithImage:nil num:self.puzzle.numberofPieces sideLenX:sideLengthX sideLenY:sideLengthY];
        
        // create all of the pieces of the puzzle
        [self createVerticalPieceViewInRect:pieceRect WithImage:self.puzzle.puzzleImage num:self.puzzle.numberofPieces sideLenX:sideLengthX sideLenY:sideLengthY];
    }
    
    else {
        NSLog(@"No image selected.");
    }
}

-(void)createSquarePuzzleWithGridSize:(NSInteger)size {
    if (self.puzzle.puzzleImage) { // if the image from the preview controller was assigned to this
        NSLog(@"Puzzle Image Width: %f     Puzzle Image Height: %f", self.puzzle.puzzleImage.size.width, self.puzzle.puzzleImage.size.height);
        
        CGFloat sideLengthY = self.puzzle.puzzleImage.size.height/sqrt(self.puzzle.numberofPieces); // sideLengthY is the length of each PieceView/TargetView. Formula: length of photo (or height) divided by # of pieces in Y-axis = sideLengthY (if we want not X by X we need two pieceNums?********** like 7x4. REMEMBER THIS.)
        CGFloat sideLengthX = self.puzzle.puzzleImage.size.width/sqrt(self.puzzle.numberofPieces); // sideLengthX is the width of each PieceView/TargetView. Formula: width of photo (or height) divided by # of pieces in X-axis = sideLengthX
        // NSLog(@"sideLengthY: %f     sideLengthX: %f", sideLengthY, sideLengthX);
        
        CGRect targetRect;
        CGRect pieceRect;
        
        // this is the place of the very first target view.
        targetRect = CGRectMake((self.frame.size.width - self.puzzle.puzzleImage.size.width) / 2, (self.frame.size.height - self.puzzle.puzzleImage.size.height) / 2, 200, 200); // 200s do nothing, just placeholders
        
        // this is the place of the very first piece view.
        pieceRect = CGRectMake((self.frame.size.width - self.puzzle.puzzleImage.size.width) / 2, (self.frame.size.height - self.puzzle.puzzleImage.size.height), 200, 200); // 200s do nothing, just placeholders
   
        // create all of the target views of the puzzle
        [self createVerticalTargetViewInRect:targetRect WithImage:nil num:self.puzzle.numberofPieces sideLenX:sideLengthX sideLenY:sideLengthY]; // this works for square puzzles as well.
        
        // create all of the pieces of the puzzle
        [self createVerticalPieceViewInRect:pieceRect WithImage:self.puzzle.puzzleImage num:self.puzzle.numberofPieces sideLenX:sideLengthX sideLenY:sideLengthY]; // this works for square puzzles as well
    }
    
    else {
        NSLog(@"No image selected.");
    }
}

// if a piece is dragged, check if it can fit in a TargetView
-(void)pieceView:(PieceView *)currentPieceView didDragToPoint: (CGPoint)pt{
    PieceView* nonCurrentPieceView;
    for (TargetView* nonCurrentTargetView in self.puzzle.targets) { // self.targets is the array of TargetViews
        if (CGRectContainsPoint(nonCurrentTargetView.frame, pt)) { // if the piece is dragged near a target
            
            // if it exists, get the pieceview that's about to be swapped (the noncurrent piece view) and place it on current pieceview's old targetview
            for (PieceView* aPieceView in self.puzzle.pieces) {
                
                // find the piece view about to be swapped, which lies on the non current target view
                if (aPieceView.targetView == nonCurrentTargetView) {
                    nonCurrentPieceView = aPieceView; // piece view about to be swapped
                    
                    // if the non current piece view isn't matched, we can place it
                    if (!nonCurrentPieceView.isMatched) {
                        // place non current piece view on current pieceview's old targetview
                        nonCurrentPieceView.targetView = currentPieceView.targetView;
                        nonCurrentPieceView.center = currentPieceView.targetView.center;
                        break;
                    }
                    
                    else if (nonCurrentPieceView.isMatched) {
                        currentPieceView.center = currentPieceView.targetView.center;
                        NSLog(@"this non current piece view is already matched, try placing the current piece view somewhere else.");
                        break;
                    }
                }
            }
            
            if (nonCurrentPieceView) { // if we have a noncurrent piece view, we might be able to place the current piece view, or not
                if (!nonCurrentPieceView.isMatched) {
                    // place the current piece view on the nearest target, which in this case is the noncurrent piece view's target
                    currentPieceView.targetView = nonCurrentTargetView;
                    currentPieceView.center = currentPieceView.targetView.center;
                    break;
                }
                else if (!nonCurrentPieceView.isMatched) {
                    NSLog(@"this non current piece view is already matched, try placing the current piece view somewhere else.");
                    break;
                }
            }
            
            else if (nonCurrentPieceView == nil) { // if we don't have a noncurrent piece view, we will be placing the current piece in an empty target
                // place the current piece view on the nearest target, which in this case is empty
                currentPieceView.targetView = nonCurrentTargetView; // place it back to original spot if it can't be placed
                currentPieceView.center = currentPieceView.targetView.center;
                break;
            }
        }
    }
    
    // check if current piece is matched to its target
    if (currentPieceView.pieceId == currentPieceView.targetView.targetId) {
        currentPieceView.isMatched = true; // if matched, set it to true
        currentPieceView.userInteractionEnabled = false;
        currentPieceView.layer.borderWidth = 0;
        currentPieceView.layer.borderColor = nil;
    } else{
        currentPieceView.isMatched = false; // if it's not matched, set it to false
    }
    
    // check if non-current piece - the piece being swapped - is matched to its target
    if (nonCurrentPieceView.pieceId == nonCurrentPieceView.targetView.targetId) {
        nonCurrentPieceView.isMatched = true; // if matched, set it to true
        nonCurrentPieceView.userInteractionEnabled = false;
        nonCurrentPieceView.layer.borderWidth = 0;
        nonCurrentPieceView.layer.borderColor = nil;
    } else{
        nonCurrentPieceView.isMatched = false; // if it's not matched, set it to false
    }
    
    if ([self.puzzle puzzleSolved]) {
        NSLog(@"Puzzle solved - Game over.");
    }
}

# pragma mark - navigation methods

- (IBAction)pauseButtonDidPress:(id)sender {
    [self.delegate pause]; // pause the timer, perform the segue
}


# pragma mark - timer methods

-(void)updateTimerLabel:(NSNumber*)totalSeconds {
    int intValueTotalSeconds = [totalSeconds intValue];
    int minutes = 0; int seconds = 0; int hours = 0;
    
    seconds = intValueTotalSeconds % 60;
    if (intValueTotalSeconds >= 60) {
        minutes = intValueTotalSeconds / 60;
    }
    
   /* else if (intValueTotalSeconds >= 3600) {
        hours = intValueTotalSeconds / 3600;
        intValueTotalSeconds = intValueTotalSeconds - 3600;
        minutes = intValueTotalSeconds / 60;
        seconds = intValueTotalSeconds % 60;
    } */
  
    if (seconds < 10) {
        self.timerLabel.text = [NSString stringWithFormat:@"%d:0%d", minutes, seconds];
    }
    
    else if (seconds >= 10) {
        self.timerLabel.text = [NSString stringWithFormat:@"%d:%d", minutes, seconds];
    }
}


#pragma mark - helper methods

// create a hex color
-(UIColor*)colorWithHexString:(NSString*)hex {
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

#pragma mark - image methods

-(UIImage*)prepareImageForGame:(UIImage*)image {
    // for photos from library you need to resize resize the photo
    if (image.size.height > image.size.width) { // portrait; resizing photo so it fits the entire device screen
        self.puzzle.puzzleImage = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.superview.frame.size.width, self.superview.frame.size.height - 30)];
    }
    
    else if (image.size.width > image.size.height) { // landscape
        self.puzzle.puzzleImage = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.superview.frame.size.width, self.superview.frame.size.height - 30)];
    }
    
    else if (image.size.width == image.size.height) { // square
        self.puzzle.puzzleImage = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.superview.frame.size.width, self.superview.frame.size.height - 30)];
    }
    
    NSLog(@"image after resizing: %@", image);
    return image;
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// split the image into pieceNum pieces and return an array
- (NSMutableArray *)splitImageWith: (UIImage *)image andPieceNum: (NSInteger)pieceNum{
    NSMutableArray* images = [NSMutableArray arrayWithCapacity:(NSUInteger)pieceNum];
    NSInteger side = sqrt(pieceNum);
    NSLog(@"pieceNum: %ld   side: %ld", (long)pieceNum, (long)side);
    CGFloat x = 0.0, y = 0.0;
    CGFloat sideLengthY = self.puzzle.puzzleImage.size.height/side; // sideLengthY is the length of each PieceView/TargetView. Formula: length of photo (or height) divided by # of pieces in Y-axis = sideLengthY (if we want not X by X we need two pieceNums?********** like 7x4. REMEMBER THIS.)
    CGFloat sideLengthX = self.puzzle.puzzleImage.size.width/side; // sideLengthX is the width of each PieceView/TargetView. Formula: width of photo (or height) divided by # of pieces in X-axis = sideLengthX
    //NSLog(@"sideLengthY: %f     sideLengthX: %f", sideLengthY, sideLengthX);
    
    for (int row = 0; row < side; row++) {
        x = 0.0;
        for (int col = 0; col < side; col++) {
            CGRect rect = CGRectMake(x, y, sideLengthX, sideLengthY);
            CGImageRef cImage = CGImageCreateWithImageInRect([image CGImage],  rect); // coregraphics method!
            UIImage* dImage = [[UIImage alloc]initWithCGImage:cImage];
            NSLog(@"cImage: %@   dImage: %@", cImage, dImage);
            [images addObject:dImage];
            x = x + sideLengthX;
        }
        y = y + sideLengthY;
    }
    return images;
}

@end
