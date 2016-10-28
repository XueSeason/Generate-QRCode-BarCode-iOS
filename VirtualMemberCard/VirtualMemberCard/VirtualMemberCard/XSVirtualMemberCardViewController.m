//
//  XSVirtualMemberCardViewController.m
//  VirtualMemberCard
//
//  Created by 薛纪杰 on 15/8/10.
//  Copyright (c) 2015年 薛纪杰. All rights reserved.
//

#import "XSVirtualMemberCardViewController.h"

#import "AFNetworking.h"
#import "MBProgressHUD.h"

#define kThemeColor [UIColor colorWithRed:223 / 255.0 green:24 / 255.0 blue:37 / 255.0 alpha:1.0];

NSString * const protocol = @"http";
NSString * const address  = @"localhost";
NSString * const port     = @"3000";

@interface XSVirtualMemberCardViewController ()

@property (strong, nonatomic) NSString *code;
@property (assign, nonatomic) CGFloat  currentBrightness;

@property (weak, nonatomic)   IBOutlet UIView         *broadcastView;
@property (weak, nonatomic)   IBOutlet UIScrollView   *scrollView;
@property (strong, nonatomic)          UILabel        *adContentLabel;
@property (strong, nonatomic)          NSTimer        *scrollTimer;

@property (weak, nonatomic)   IBOutlet UIButton       *accessButton;

@property (weak, nonatomic)   IBOutlet UIView         *rectView;
@property (weak, nonatomic)   IBOutlet UIImageView    *barCodeImageView;
@property (weak, nonatomic)   IBOutlet UIImageView    *qrCodeImageView;
@property (weak, nonatomic)   IBOutlet UILabel        *barCodeLabel;

@property (strong, nonatomic)          UIView         *barCodeContentView;
@property (strong, nonatomic)          UIView         *qrCodeContentView;
@property (strong, nonatomic)          UIImageView    *barCodeSizeImageView;
@property (strong, nonatomic)          UIImageView    *qrCodeSizeImageView;
@property (strong, nonatomic)          UILabel        *barCodeSizeLabel;

@property (weak, nonatomic)   IBOutlet UIProgressView *progressView;
@property (strong, nonatomic)          NSTimer        *progressTimer;

@property (strong, nonatomic)          NSDictionary   *jsonDict;

@end

@implementation XSVirtualMemberCardViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    /**
     *  设置导航栏
     */
    self.navigationItem.title = @"虚拟会员卡";
    UIBarButtonItem *refreshButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Refresh.png"] style:UIBarButtonItemStyleDone target:self action:@selector(reloadQRCodeAndBarCode)];
    self.navigationItem.rightBarButtonItem = refreshButtonItem;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationController.navigationBar.backgroundColor = kThemeColor;
    self.navigationController.navigationBar.barTintColor = kThemeColor;
    /**
     *  设置广播栏
     */
    // 禁止手动滚动
    _scrollView.scrollEnabled = NO;
    _adContentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 34)];
    [_scrollView addSubview:_adContentLabel];
    _scrollView.contentSize = _adContentLabel.frame.size;
    _adContentLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    _adContentLabel.text = @"尊敬的三江用户，点击绑定会员卡，享受更多优惠。";
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(scroll) userInfo:nil repeats:YES];
    // 添加事件
    _broadcastView.userInteractionEnabled = YES;
    [_broadcastView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(click:)]];
    
    _accessButton.tintColor = kThemeColor;
    
    /**
     *  设置条形码和二维码
     */
    _qrCodeContentView = [[UIImageView alloc] init];
    _qrCodeImageView.userInteractionEnabled = YES;
    _barCodeContentView = [[UIImageView alloc] init];
    _barCodeImageView.userInteractionEnabled = YES;
    
    /**
     *  设置进度条
     */
    _progressView.trackTintColor = [UIColor colorWithRed:214 / 255.0 green:214 / 255.0 blue:214 / 255.0 alpha:1.0];
    _progressView.progressTintColor = kThemeColor;
    
    /**
     *  加载数据
     */
    [self loadQRCodeAndBarCode];
    
}

#pragma mark - 点击
- (IBAction)click:(id)sender {
    NSLog(@"click");
}

- (void)tapQRCodeBigger
{
    _currentBrightness = [UIScreen mainScreen].brightness;
    
    // 调整屏幕亮度
    [[UIScreen mainScreen] setBrightness:1.0];
    
    // 隐藏导航栏
    self.navigationController.navigationBarHidden = YES;

    // 创建全屏背景图
    _qrCodeContentView.frame = [UIScreen mainScreen].bounds;
    _qrCodeContentView.backgroundColor = [UIColor whiteColor];

    // 创建image view
    _qrCodeSizeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _qrCodeImageView.frame.size.width * 1.2, _qrCodeImageView.frame.size.height * 1.2)];
    _qrCodeSizeImageView.center = CGPointMake(_qrCodeContentView.frame.size.width / 2.0, _qrCodeContentView.frame.size.height / 2.0);
    _qrCodeSizeImageView.image = [UIImage imageWithCIImage:[_qrCodeImageView.image CIImage]];
    [_qrCodeContentView addSubview:_qrCodeSizeImageView];
    
    [self.view addSubview:_qrCodeContentView];
    [self.view bringSubviewToFront:_qrCodeContentView];
    
    _qrCodeContentView.userInteractionEnabled = YES;
    [_qrCodeContentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapQRCodeSmaller)]];
}

- (void)tapQRCodeSmaller
{
    self.navigationController.navigationBarHidden = NO;
    [_qrCodeContentView removeFromSuperview];
    [_qrCodeSizeImageView removeFromSuperview];
    [[UIScreen mainScreen] setBrightness:_currentBrightness];
}

- (void)tapBarCodeBigger
{
    _currentBrightness = [UIScreen mainScreen].brightness;
    // 调整屏幕亮度
    [[UIScreen mainScreen] setBrightness:1.0];

    // 隐藏导航栏
    self.navigationController.navigationBarHidden = YES;
    
    // 创建全屏背景图
    _barCodeContentView.frame = [UIScreen mainScreen].bounds;
    _barCodeContentView.backgroundColor = [UIColor whiteColor];
    
    // 创建image view
    _barCodeSizeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _barCodeImageView.frame.size.width * 1.5, _barCodeImageView.frame.size.height * 1.5)];
    _barCodeSizeImageView.center = CGPointMake(_barCodeContentView.frame.size.width / 2.0, _barCodeContentView.frame.size.height / 2.0);
    _barCodeSizeImageView.image = [UIImage imageWithCIImage:[_barCodeImageView.image CIImage] scale:1.0 orientation:UIImageOrientationUp];
    _barCodeSizeImageView.transform = CGAffineTransformMakeRotation(M_PI / 2);
    [_barCodeContentView addSubview:_barCodeSizeImageView];

    // 创建label
    _barCodeSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _barCodeSizeImageView.frame.size.height, 44)];
    _barCodeSizeLabel.textAlignment = NSTextAlignmentCenter;
    _barCodeSizeLabel.center = CGPointMake(_barCodeSizeImageView.center.x - 60, _barCodeSizeImageView.center.y);
    _barCodeSizeLabel.text = [self formatCode:_code];
    _barCodeSizeLabel.transform = CGAffineTransformMakeRotation(M_PI / 2);
    [_barCodeContentView addSubview:_barCodeSizeLabel];
    
    [self.view addSubview:_barCodeContentView];
    [self.view bringSubviewToFront:_barCodeContentView];
    
    _barCodeContentView.userInteractionEnabled = YES;
    [_barCodeContentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBarCodeSmaller)]];
}

- (void)tapBarCodeSmaller
{
    self.navigationController.navigationBarHidden = NO;
    [_barCodeContentView removeFromSuperview];
    [_barCodeSizeLabel removeFromSuperview];
    [_barCodeSizeImageView removeFromSuperview];
    [[UIScreen mainScreen] setBrightness:_currentBrightness];
}

#pragma mark - 循环滚动
- (void)scroll {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
    [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x + 10, 0) animated:NO];
    
    [UIView commitAnimations];
    
    if (_scrollView.contentOffset.x > _adContentLabel.frame.size.width) {
        _scrollView.contentOffset = CGPointMake(-_adContentLabel.frame.size.width, 0);
    }
}

#pragma mark - 加载条形码以及二维码
- (void)reloadQRCodeAndBarCode {
    [MBProgressHUD showHUDAddedTo:_rectView animated:YES];
    [_progressTimer invalidate];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self loadDataFromService];
}

- (void)loadQRCodeAndBarCode {
    // 异步加载
    [MBProgressHUD showHUDAddedTo:_rectView animated:YES];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    __weak XSVirtualMemberCardViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 耗时操作
        [weakSelf loadDataFromService];
        
        // 切换到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    });
}

- (void)loadDataFromService {
    // GET请求
    NSString *URLString = [NSString stringWithFormat:@"%@://%@:%@", protocol, address, port];
    NSDictionary *parameters = @{};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    
    __weak XSVirtualMemberCardViewController *weakSelf = self;
    [manager GET:URLString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        // 回调函数
        NSError *error;
        weakSelf.jsonDict = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Parser: %@", error);
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"获取数据异常" message:@"无法解析服务器数据" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
            [MBProgressHUD hideHUDForView:weakSelf.rectView animated:YES];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return;
        }
        
        if (!([[weakSelf.jsonDict objectForKey:@"Status"] intValue] == 0)) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"获取数据异常" message:@"无法从服务器获取正确的数据" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
            [MBProgressHUD hideHUDForView:weakSelf.rectView animated:YES];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"Status Exception.");
            return;
        }
        
        // 输出获取到的数据
        NSLog(@"%@", weakSelf.jsonDict);
        
        weakSelf.code = [[weakSelf.jsonDict objectForKey:@"Data"] objectForKey:@"Code"];
        weakSelf.barCodeLabel.text = [self formatCode:weakSelf.code];
        NSInteger time = [[[weakSelf.jsonDict objectForKey:@"Data"] objectForKey:@"Time"] integerValue];
        weakSelf.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(progressChanged) userInfo:nil repeats:YES];
        
        // 设置倒计时进度条
        weakSelf.progressView.progress = time / 55.0;
        
        // 生成条形码
        weakSelf.barCodeImageView.image = [self generateBarCode:weakSelf.code width:weakSelf.barCodeImageView.frame.size.width height:weakSelf.barCodeImageView.frame.size.height];
        if (weakSelf.barCodeContentView.frame.size.width != 0 && weakSelf.barCodeContentView.frame.size.height != 0) {
            NSLog(@"重新加载条形码");
            weakSelf.barCodeSizeImageView.image = [UIImage imageWithCIImage:[weakSelf.barCodeImageView.image CIImage] scale:1.0 orientation:UIImageOrientationRight];
            weakSelf.barCodeSizeLabel.text = [self formatCode:weakSelf.code];
        }
        
        // 生成二维码
        weakSelf.qrCodeImageView.image = [self generateQRCode:weakSelf.code width:weakSelf.qrCodeImageView.frame.size.width height:weakSelf.qrCodeImageView.frame.size.height];
        if (weakSelf.qrCodeContentView.frame.size.width != 0 && weakSelf.qrCodeContentView.frame.size.height != 0) {
            NSLog(@"重新加载二维码");
            weakSelf.qrCodeSizeImageView.image = [UIImage imageWithCIImage:[weakSelf.qrCodeImageView.image CIImage]];
        }
        
        // 添加放大事件
        [weakSelf.qrCodeImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapQRCodeBigger)]];
        [weakSelf.barCodeImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBarCodeBigger)]];
        
        [MBProgressHUD hideHUDForView:weakSelf.rectView animated:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"获取数据失败" message:@"无法连接到服务器" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        NSLog(@"GET JSON Error: %@", error);
        [MBProgressHUD hideHUDForView:weakSelf.rectView animated:YES];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
    
}
#pragma mark - 格式化code
// 每隔4个字符空两格
- (NSString *)formatCode:(NSString *)code {
    NSMutableArray *chars = [[NSMutableArray alloc] init];
    
    for (int i = 0, j = 0 ; i < [code length]; i++, j++) {
        [chars addObject:[NSNumber numberWithChar:[code characterAtIndex:i]]];
        if (j == 3) {
            j = -1;
            [chars addObject:[NSNumber numberWithChar:' ']];
            [chars addObject:[NSNumber numberWithChar:' ']];
        }
    }
    
    int length = (int)[chars count];
    char str[length];
    for (int i = 0; i < length; i++) {
        str[i] = [chars[i] charValue];
    }
    
    NSString *temp = [NSString stringWithUTF8String:str];
    return temp;
}

#pragma mark - 改变进度条进度
- (void)progressChanged {
    
    CGFloat step = 1.0 / 55.0;
    
    [_progressView setProgress:_progressView.progress - step animated:YES];
    
    if (_progressView.progress <= 0.0) {
        [_progressTimer invalidate];
        [self reloadQRCodeAndBarCode];
    }
    
}

#pragma mark - 生成条形码以及二维码

// 参考文档
// https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html

- (UIImage *)generateQRCode:(NSString *)code width:(CGFloat)width height:(CGFloat)height {
    
    // 生成二维码图片
    CIImage *qrcodeImage;
    NSData *data = [_code dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    qrcodeImage = [filter outputImage];
    
    // 消除模糊
    CGFloat scaleX = width / qrcodeImage.extent.size.width; // extent 返回图片的frame
    CGFloat scaleY = height / qrcodeImage.extent.size.height;
    CIImage *transformedImage = [qrcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}

- (UIImage *)generateBarCode:(NSString *)code width:(CGFloat)width height:(CGFloat)height {
    // 生成二维码图片
    CIImage *barcodeImage;
    NSData *data = [_code dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    
    [filter setValue:data forKey:@"inputMessage"];
    barcodeImage = [filter outputImage];
    
    // 消除模糊
    CGFloat scaleX = width / barcodeImage.extent.size.width; // extent 返回图片的frame
    CGFloat scaleY = height / barcodeImage.extent.size.height;
    CIImage *transformedImage = [barcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}

@end
