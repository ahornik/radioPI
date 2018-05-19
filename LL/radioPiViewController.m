//
//  radioPiViewController.m
//
//  Created by Armand Hornik on 09/04/16.
//  Copyright (c) 2016 Armand Hornik. All rights reserved.
//

#import "radioPiViewController.h"

@interface radioPiViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *myHelpWeb;
@property (weak, nonatomic) IBOutlet UIButton *myHelpButton;
@property (weak, nonatomic) IBOutlet UIButton *view1Button;
@property (weak, nonatomic) IBOutlet UISwitch *On_Off;
@property (weak, nonatomic) IBOutlet UISwitch *On_Off_2;
@property (weak, nonatomic) IBOutlet UISwitch *On_Off_3;
@property (weak, nonatomic) IBOutlet UIButton *ValTemp;
@property (weak, nonatomic) IBOutlet UIButton *ValHum;
@property (weak, nonatomic) IBOutlet UIButton *ValPres;
@property (weak, nonatomic) IBOutlet UITextField *gesture;
@property (weak, nonatomic) IBOutlet UITextField *Status_Text;
@property (weak, nonatomic) IBOutlet UITextField *Status_Text1;
@property (weak, nonatomic) IBOutlet UITextField *Status_Text2;
@property (weak, nonatomic) IBOutlet UIButton *VolP;
@property (weak, nonatomic) IBOutlet UIButton *VolM;
@property (weak, nonatomic) IBOutlet UILabel *ValAlt;
@property (weak, nonatomic) IBOutlet UIImageView *imageview;
@property (weak, nonatomic) IBOutlet UIButton *PresBut;
@property (weak, nonatomic) IBOutlet UIButton *MENU;
@property (weak, nonatomic) IBOutlet UIButton *Mute;
@property (weak, nonatomic) IBOutlet UIImageView *MyRemote;
@property (weak, nonatomic) IBOutlet UILabel *DescStation;
@property (strong, nonatomic) IBOutlet UIPickerView *PickerCategory;
@property (weak, nonatomic) IBOutlet UIPickerView *PickerStation;
@property (weak, nonatomic) IBOutlet UITextField *VolumeLevel;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *SwipeToLeft;
@property (weak, nonatomic) IBOutlet UITextField *add1;
@property (weak, nonatomic) IBOutlet UITextField *add2;
@property (weak, nonatomic) IBOutlet UITextField *add3;
@property (weak, nonatomic) IBOutlet UITextField *add4;
@property (weak, nonatomic) IBOutlet UITextField *DataFile;
@property (weak, nonatomic) IBOutlet UIButton *AltBut;
@end

@implementation radioPiViewController

#define OPENING 1
#define OPEN 2
#define CLOSED 3

#define RIGHT 1
#define LEFT 0

static Boolean Request_Close=false;
static int lastCategory=0;
static int lastStation=0;
static int Status=CLOSED;
static int Quest=0;
static int Direction=RIGHT;
static int LastScreen=1;
static NSString *SaveTemp=NULL;
static NSString *SavePress=NULL;
static NSString *SaveHumid=NULL;
static NSString *SaveAlt=NULL;
static NSString *Address1=@"192.168.1.20";
static NSString *Address2=@"192.168.1.235";
static NSString *Address3=@"192.168.1.233";
static int Digit1=192,Digit2=168,Digit3=1,Digit4=233;
static int Volume=-1;
static UIColor * OK_text;
static UIColor * OK_Waiting;
static UIColor * OK_Bad;
static UIImage * buttonImageH;
static UIImage * buttonImageR;
static bool isInitialized=false;

static NSArray *_pickerData;
static NSMutableArray *_pickerStation;
NSString *tmpCat,*tmpName,*tmpUrl;

static UIButton *PgmHelpBut;
static int PgmHelpState=0;

- (void)CreateHelpBut
{
    PgmHelpBut = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [PgmHelpBut addTarget:self action:@selector(myHelpAction:) forControlEvents:UIControlEventTouchUpInside];
    [PgmHelpBut setFrame:CGRectMake(281, 27, 33, 33)];
    [PgmHelpBut setTitle:@"" forState:UIControlStateNormal];
    [PgmHelpBut setExclusiveTouch:YES];
    
    // if you like to add backgroundImage else no need
    [PgmHelpBut  setBackgroundImage:[UIImage imageNamed:@"Help.png"] forState:UIControlStateNormal];
    PgmHelpState=1;
    [self.view addSubview:PgmHelpBut];
    NSLog(@"LastScreen = %d",LastScreen);

}
-(UIColor *)colorFromHex:(NSString *)hex {
    unsigned int c;
    if ([hex characterAtIndex:0] == '#') {
        [[NSScanner scannerWithString:[hex substringFromIndex:1]] scanHexInt:&c];
    } else {
        [[NSScanner scannerWithString:hex] scanHexInt:&c];
    }
    return [UIColor colorWithRed:((c & 0xff0000) >> 16)/255.0
                           green:((c & 0xff00) >> 8)/255.0
                            blue:(c & 0xff)/255.0 alpha:1.0];
}
- (IBAction)myHelpAction:(id)sender {
    if (_myHelpWeb.hidden==false)
    {
        _myHelpWeb.hidden=true;
        PgmHelpState=1;
        [PgmHelpBut setBackgroundImage:[UIImage imageNamed:@"Help.png"] forState:UIControlStateNormal];

    }
    else
    {
        _myHelpWeb.hidden=false;
        PgmHelpState=0;
        [PgmHelpBut setBackgroundImage:[UIImage imageNamed:@"Retour.png"] forState:UIControlStateNormal];

    }
}
-(void) SetColorStatus:(UIColor*)Col
{
    [    _Status_Text  setTextColor:Col ];
    [    _Status_Text1  setTextColor:Col ];
    [    _Status_Text2 setTextColor:Col ];
    
}

- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)Address3, 10000, &readStream, &writeStream);
    inputStream = (NSInputStream *)CFBridgingRelease(readStream);
    outputStream = (NSOutputStream *)CFBridgingRelease(writeStream);
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
    Status=OPENING;
    [self SetButtons:false];
    [ _Status_Text setText:@"Connecting..."];

    [ _Status_Text1 setText:@"Connecting..."];
    [ _Status_Text2 setText:@"Connecting..."];
    [self SetColorStatus:OK_Waiting];
}

- (IBAction)Action_Connect:(id)sender {
    if([sender isOn]){
        NSLog(@"Switch is ON");
        Request_Close=false;
        [self initNetworkCommunication];
    } else{
        NSLog(@"Switch is OFF");
        [inputStream close];
        [outputStream close];
        Status = CLOSED;
        [self SetButtons:false];
        Request_Close=true;
        [ _Status_Text setText:@"Disconnected"];
        [ _Status_Text1 setText:@"Disconnected"];
        [ _Status_Text2 setText:@"Disconnected"];
        [self SetColorStatus:OK_Bad];

    }

}
- (void) SetButtons:(BOOL)Enab
{
}

-(int) StartsWithVol:(NSString *)str {
    NSRange range = [str rangeOfString:@"vol://"];
    if(range.length) {
        NSRange rangeend = [str rangeOfString:@" " options:NSLiteralSearch range:NSMakeRange(range.location,[str length] - range.location - 1)];
        if(rangeend.length) {
            return [ [str substringWithRange:NSMakeRange(range.location,rangeend.location - range.location)] intValue]; // Probably buggy should be + range.length for first argument of NSMAKERANGE but this is not relevant for the testcase
        }
        else
        {
            return [ [str substringFromIndex:range.location+range.length] intValue];
        }
    }
    else {
        return Volume;
    }
}
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            Status=OPEN;
            [self SetButtons:true];
            
            [ _On_Off setOn:true];
            [ _On_Off_2 setOn:true];
            [ _On_Off_3 setOn:true];
            [ _Status_Text setText:@"Connected"];
            [ _Status_Text1 setText:@"Connected"];
            [ _Status_Text2 setText:@"Connected"];
            [self SetColorStatus:OK_text];

            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Receive Data");
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable])
                {
                    len = (int)[inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output)
                        {
                            [self SetButtons:true];
                            
                            NSLog(@"server said: %@", output);
                            if (Quest == 0)
                            {
                                
                                
                                Volume =[self StartsWithVol:output];
                                if (Volume!= -1)
                                {
                                    NSString *str = [NSString stringWithFormat:@"%02d %%",Volume];
                                    [ _VolumeLevel setText:str];
                                }
                            }
                            else if (Quest==2)
                            {
                                output=[output stringByAppendingString:@"º"];
                                [_ValTemp setTitle:output forState:UIControlStateNormal];
                                SaveTemp=output;
                            }
                            else if (Quest ==1)
                            {
                                output=[output stringByAppendingString:@"%"];
                                [_ValHum setTitle:output forState:UIControlStateNormal];
                                SaveHumid=output;
                            }
                            else if (Quest == 3)
                            {
                                double doubleValue = [output doubleValue];
                                doubleValue/= 100;
                                output=[NSString stringWithFormat:@"%2.02fHpa", doubleValue];
                                //output=[output stringByAppendingString:@"HPa"];
                                [_ValPres setTitle:output forState:UIControlStateNormal];
                                SavePress=output;
                                
                            }if (Quest ==4)
                            {
                                output=[output stringByAppendingString:@"m"];
                                [_ValAlt setText:output];
                                SaveAlt=output;
                            }
                            
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            Status= CLOSED;
            [self SetButtons:false];
            
            [ _Status_Text setText:@"Disconnected - Error"];
            [ _Status_Text1 setText:@"Disconnected - Error"];
            [ _Status_Text2 setText:@"Disconnected - Error"];
            [self SetColorStatus:OK_Bad];

            [ _On_Off setOn:false];
            [ _On_Off_2 setOn:false];
            [ _On_Off_3 setOn:false];
            
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Connexion is closed");
            Status=CLOSED;
            [self SetButtons:false];
            
            [ _Status_Text setText:@"Disconnected by remote"];
            [ _Status_Text1 setText:@"Disconnected by remote"];
            [ _Status_Text2 setText:@"Disconnected by remote"];
            [self SetColorStatus:OK_Bad];

            [ _On_Off setOn:false];
            [ _On_Off_2 setOn:false];
            [ _On_Off_3 setOn:false];
            
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Space available");
            break;
        default:
            NSLog(@"Unknown event");
    }
}
- (IBAction)Action_SWIPELEFT:(id)sender {
    Direction=RIGHT;
}
- (IBAction)Action_SWIPERIGHT:(id)sender {
    Direction=LEFT;
}

- (IBAction)SetRadio:(id)sender {
}


-(void) NewInitializeButtons:(int)row
{
    // CurrentSegue
    // ListOfNSSegue[]
    // Max_Title
    // CurrentPoint
    //arrayOfButtons[]
    int i,j;
    _pickerStation= [[NSMutableArray alloc] init];
    
    
    
    for (j=0,i=0;i<Max_titles;i++)
    {
        if ([[_pickerData[row] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:[[NSString stringWithUTF8String:RadioInit[i].Category] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]])
        {
            [_pickerStation addObject:[[NSString stringWithUTF8String:RadioInit[i].Comment]  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            ListPageRadio[j]=RadioInit[i];
            j++;
        }
        
    }
    
    [_PickerStation selectRow:j-1 inComponent:0 animated:YES];
    [_PickerStation selectRow:0 inComponent:0 animated:YES];

    [_DescStation setText:LastRadio ];
}




- (IBAction)SelectRadio:(id)sender {
    int tag = (int)[sender tag];
    
    NSLog(@"this is bug %d",tag);
    UIButton *but=(UIButton *)sender;
    NSString *response;
    if (Status == CLOSED)
    {
        NSLog(@"Connexion has been closed - reopening ");
        
        [ self initNetworkCommunication];
        return;
    }
    if (but.tag <=15)
    {
        int row = (int)[_PickerStation selectedRowInComponent:0];
        response = [[NSString stringWithFormat:@"mplayer %s",ListPageRadio[row].Url]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        LastRadio=[[NSString stringWithUTF8String:ListPageRadio[row].Comment]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [_DescStation setText:LastRadio ];
    }
    switch (but.tag)
    {
        case 100:
            response  = [NSString stringWithFormat:@"kill mplayer"];
            break;
        case 110:
            if (Volume!=-1) { Volume+=5; if (Volume>=100) Volume=100;}
            if (Volume!= -1)
            {
                [ _VolumeLevel setText:[NSString stringWithFormat:@"%02d %%",Volume]];
            }

            
            response  = [NSString stringWithFormat:@"VolumeUp"];
            break;
        case 105:
            if (Volume!=-1) { Volume-=5; if (Volume<=0) Volume=0;}
            if (Volume!= -1)
            {
                [ _VolumeLevel setText:[NSString stringWithFormat:@"%02d %%",Volume]];
            }
            

            response  = [NSString stringWithFormat:@"VolumeDown"];
            break;
        case 120:
            //[self Initialize_buttons];
            return ;
            break;
        case 125:
            //Current_Point-=60;
            //if (Current_Point<0) Current_Point+=Max_titles+2;
            
            //[self Initialize_buttons];
            return ;
            break;
        default:
            break;
    }
    
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    Max_titles=(sizeof(RadioInit)/sizeof(RadioT));

    // Do any additional setup after loading the view, typically from a nib.
    //_pickerData = @[@"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5", @"Item 6"];
    _pickerData = @[[@NATIONALES stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@INTERNATIONALES stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@INFORMATIONS stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@REGIONALES stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@LOCALES stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@DANCES stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@BLUES stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@ROCK stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@JAZZ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@MISC stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@LATIN stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@CLASSIC stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@PIANO stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
                    [@JEWISH stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                    ];
    self.PickerCategory.dataSource = self;
    self.PickerCategory.delegate = self;
    if (_view1Button.enabled)
    {
        // Only use the help button in screen 1
        [self CreateHelpBut];
    }
    self.PickerStation.dataSource = self;
    self.PickerStation.delegate = self;
    //_VolumeLevel.delegate = self;
    int i=0;
    OK_text=[self colorFromHex:@"0x00ff00"];
    OK_Bad=[self colorFromHex:@"0xff0000"];
    OK_Waiting=[self colorFromHex:@"0xff8000"];
    
    
    NSURL *localURL = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"];
    
    
    
    
    [_myHelpWeb loadRequest:[NSURLRequest requestWithURL:localURL]];
    _myHelpWeb.hidden=true;
    if (isInitialized==false)
    {
        [self loadPreferences];
        isInitialized=true;
    }

    
    
    for (i=0;i<NbCategory;i++)
    {
        ListOfNSSegue[i]=[[NSString stringWithUTF8String:ListOfSegue[i]]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    // Do any additional setup after loading the view.
    [_PickerCategory selectRow:lastCategory inComponent:0 animated:YES];
    
    [self NewInitializeButtons:lastCategory];
    [_PickerStation selectRow:lastStation inComponent:0 animated:YES];
    
    
    
    if ((Request_Close == false) && (Status != OPEN))
        [self initNetworkCommunication];
    switch (Status)
    {
        case OPEN:
            [ _On_Off setOn:true];
            [ _On_Off_2 setOn:true];
            [ _On_Off_3 setOn:true];
            [ _Status_Text setText:@"Connected"];
            [ _Status_Text1 setText:@"Connected"];
            [ _Status_Text2 setText:@"Connected"];
            [self SetColorStatus:OK_text];
            
            break;
        case CLOSED:
            [ _On_Off setOn:false];
            [ _On_Off_2 setOn:false];
            [ _On_Off_3 setOn:false];
            [ _Status_Text setText:@"Disconnected"];
            [ _Status_Text1 setText:@"Disconnected"];
            [ _Status_Text2 setText:@"Disconnected"];
            [self SetColorStatus:OK_Bad];
            
            
            break;
        case OPENING:
            [ _On_Off setOn:false];
            [ _On_Off_2 setOn:false];
            [ _On_Off_3 setOn:false];
            [ _Status_Text setText:@"Connecting..."];
            [ _Status_Text1 setText:@"Connecting..."];
            [ _Status_Text2 setText:@"Connecting..."];
            [self SetColorStatus:OK_Waiting];
            
            break;
        default:
            break;
    }
    if (SaveTemp!=NULL) [_ValTemp setTitle:SaveTemp forState:UIControlStateNormal];
    if (SaveAlt!=NULL) [_ValAlt setText:SaveAlt];
    if (SavePress!=NULL) [_ValPres setTitle:SavePress forState:UIControlStateNormal];
    if (SaveHumid!=NULL) [_ValHum setTitle:SaveHumid forState:UIControlStateNormal];
    if (Volume!= -1)
    {
        [ _VolumeLevel setText:[NSString stringWithFormat:@"%02d %%",Volume]];
    }
    [ _add1 setText:[NSString stringWithFormat:@"%d",Digit1]];
    [ _add2 setText:[NSString stringWithFormat:@"%d",Digit2]];
    [ _add3 setText:[NSString stringWithFormat:@"%d",Digit3]];
    [ _add4 setText:[NSString stringWithFormat:@"%d",Digit4]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    CATransition *animation = [CATransition animation];
    
    [animation setDelegate:self];
    [animation setType:kCATransitionPush];
    if (_view1Button.enabled)
    {
        
        NSLog(@"We are in view 1");
        [animation setSubtype:kCATransitionFromLeft];
        LastScreen=1;
    }
    else if (_On_Off_2.enabled)
    {
        
        NSLog(@"We are in view 2 ");
        if (LastScreen==1)
            [animation setSubtype:kCATransitionFromRight];
        else
            [animation setSubtype:kCATransitionFromLeft];
        LastScreen=2;
        
        
    } else
    {
        NSLog(@"We are in view 3 ");
        LastScreen=3;
        
        [animation setSubtype:kCATransitionFromRight];
        
    }
    
    
    [animation setDuration:0.3];
    [animation setTimingFunction:
     [CAMediaTimingFunction functionWithName:
      kCAMediaTimingFunctionEaseInEaseOut]];
    
    [self.navigationController.view.layer addAnimation:animation forKey:kCATransition];
    [self.view.layer addAnimation:animation forKey:kCATransition];
}

- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([pickerView tag]==0)
        return (int)_pickerData.count;
    else
        return (int)_pickerStation.count;

}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([pickerView tag]==0)
        return _pickerData[row];
    else
    {
        int cc=(int)[_pickerStation count];
        if (row <cc)
            return _pickerStation[row];
        else
            return NULL;
    }
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // This method is triggered whenever the user makes a change to the picker selection.
    // The parameter named row and component represents what was selected.
    if ([pickerView tag] == 0)
    {
        NSLog(@"Selection of %ld",(long)row);
        [self NewInitializeButtons:(int)row];
        [_PickerStation reloadAllComponents];
        [_PickerStation selectRow:0 inComponent:0 animated:YES];
        
        lastCategory=(int)row;
    }
    else
    {
        NSLog(@"In station %ld",(long)row);
        lastStation=(int)row;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 60.0f;
}



-(void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"Text field did begin editing");
}

// This method is called once we complete editing
-(void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"Text field ended editing");
}

// This method enables or disables the processing of return key
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    if ([textField tag] != 666)
    {
    [textField resignFirstResponder];
    return YES;
    } else return NO;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (IBAction)Save:(id)sender {

     Digit1=[_add1.text intValue];
     Digit2=[_add2.text intValue];
     Digit3=[_add3.text intValue];
     Digit4=[_add4.text intValue];
    NSLog(@"Server Address is %d.%d.%d.%d",Digit1,Digit2,Digit3,Digit4);
    Address3=[NSString stringWithFormat:@"%d.%d.%d.%d",Digit1,Digit2,Digit3,Digit4];
    [self storeXml];
}
- (IBAction)LoadData:(id)sender {
    NSLog(@"Will load List of Radio from %@",_DataFile.text);
    [self loadPreferences];
}

-(void) loadPreferences {
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *fullFileName;
    if (isInitialized==true)
    {
        fullFileName = [NSString stringWithFormat:@"%@/%@", cacheDirectory,_DataFile.text];
    }
    else
    {
        fullFileName = [NSString stringWithFormat:@"%@/%@", cacheDirectory,DefaultPref];
        
    }
    NSLog(@"Fullfilename = %@",fullFileName);
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:fullFileName];
    [self LoadXml:data];
}

-(void) storeXml {
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    //make a file name to write the data to using the
    //cache directory:
    NSString *fullFileName = [NSString stringWithFormat:@"%@/%@", cacheDirectory,_DataFile.text];
    
    NSString * content;
    content =[ NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<ip_Address>%@</ip_Address>\n",Address3];
    
    
    
    printf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n");
        
    for(int i=0;i<Max_titles;i++)
    {
        printf("<Radio%d>\n\t<Category>%s</Category>\n\t<Name>%s<Name>\n\t<Url>%s</Url>\n</Radio%d>\n\n",i,RadioInit[i].Category,RadioInit[i].Comment,RadioInit[i].Url,i);
        content = [content stringByAppendingFormat:@"<Radio%d>\n\t<Category>%s</Category>\n\t<Name>%s</Name>\n\t<Url>%s</Url>\n</Radio%d>\n\n",
         i,RadioInit[i].Category,RadioInit[i].Comment,RadioInit[i].Url,i];
    }
    content = [content stringByAppendingFormat:@"</plist>\n"];
    content = [content stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    NSError *AnError;
    [content writeToFile:fullFileName
              atomically:NO
                encoding:NSUTF8StringEncoding
                   error:&AnError];
    

}

-(void) getCatNum
{
    
}


//********** PARSE XML FILE **********
- (void) LoadXml:(NSData *)file
{
    
    //----- PARSE THE XML -----
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:file];
    [parser setDelegate:self];
    [parser parse];
}

//***************************************************
//***************************************************
//***** PARSE XML FILE - START ELEMENT CALLBACK *****
//***************************************************
//***************************************************
- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)nameSpaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    if (!xmlString)
        xmlString = [[NSMutableString alloc] init];
    else
        [xmlString setString:@""];
    
    if ([elementName isEqual:@"SomeSection"])
    {
        //----- START OF A NEW #### SECTION -----
        //Set up for a new section of values
        
    }
}

//*****************************************************
//*****************************************************
//***** PARSE XML FILE - MORE CHARACTERS CALLBACK *****
//*****************************************************
//*****************************************************
- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    [xmlString appendString:string];
}

//*************************************************
//*************************************************
//***** PARSE XML FILE - END ELEMENT CALLBACK *****
//*************************************************
//*************************************************
- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if([elementName isEqual:@"ip_Address"])
    {
        NSString *tmpStr=xmlString;
        NSString *v[4];
        for (int i=0;i<4;i++)
        {
            NSRange rangeValue = [tmpStr rangeOfString:@"." ];
            v[i]=(i<3)?[tmpStr    substringToIndex:rangeValue.location]:tmpStr;
            if (i!=3) tmpStr=[tmpStr   substringFromIndex:rangeValue.location+rangeValue.length];
            
        }
        [_add1 setText:v[0]];
        [_add2 setText:v[1]];
        [_add3 setText:v[2]];
        [_add4 setText:v[3]];
        Digit1=[v[0] intValue];
        Digit2=[v[1] intValue];
        Digit3=[v[2] intValue];
        Digit4=[v[3] intValue];

        Address3=[NSString stringWithFormat:@"%d.%d.%d.%d",Digit1,Digit2,Digit3,Digit4];

        NSLog(@"%@ %@ %@ %@",v[0],v[1],v[2],v[3]);
        
    }else if ([elementName isEqual:@"Name"])
    {
        //----- END OF A #### ELEMENT -----
        if (xmlString != nil)
        {
            tmpName=[NSString stringWithString:xmlString];
        }
        
    } else if ([elementName isEqual:@"Category"])
    {
        //----- END OF A #### ELEMENT -----
        if (xmlString != nil)
        {
            tmpCat=[NSString stringWithString:xmlString];
        }
        
    } else if ([elementName isEqual:@"Url"])
    {
        //----- END OF A #### ELEMENT -----
        if (xmlString != nil)
        {
            tmpUrl=[NSString stringWithString:xmlString];
        }
        
    } else {
        NSRange rangeValue = [elementName rangeOfString:@"Radio" ];
        if (rangeValue.length > 0)
        {
            int nbRadio=[[elementName substringFromIndex:rangeValue.location+rangeValue.length] intValue];
            if (nbRadio < Max_titles)
            {
                NSLog(@"Substring is %@",[elementName    substringFromIndex:rangeValue.location+rangeValue.length]);
                NSLog(@"IRadio %d is cat %@ name %@ URL %@",nbRadio,tmpCat,tmpName,tmpUrl);
                tmpCat=[tmpCat stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
                tmpName=[tmpName stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
                tmpUrl=[tmpUrl stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
                
                strcpy(RadioInit[nbRadio].Category,[tmpCat UTF8String]);
                strcpy(RadioInit[nbRadio].Comment,[tmpName UTF8String]);
                strcpy(RadioInit[nbRadio].Url,[tmpUrl UTF8String]);
            }
            
        }
    }
    
}


@end
