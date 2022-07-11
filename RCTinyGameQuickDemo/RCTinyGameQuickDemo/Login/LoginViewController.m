
#import "LoginViewController.h"
#import "LoginResponse.h"
#import "LaunchManager.h"

__attribute__((unused)) static NSString * _deviceID() {
    static NSString *did = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        did = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    });
    return did;
}

@interface LoginViewController ()
@property (nonatomic, strong) UITextField *phoneNumberInputField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIViewController *homeViewController;
@end


@implementation LoginViewController

- (instancetype)initWithHomeViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.homeViewController = viewController;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self buildLayout];
}

#pragma mark getter

- (UITextField *)phoneNumberInputField {
    if (_phoneNumberInputField == nil) {
        _phoneNumberInputField = [[UITextField alloc] init];
        _phoneNumberInputField.placeholder = LocalizedString(@"login_phone_num_input_placeholder");
        _phoneNumberInputField.backgroundColor = [mainColor colorWithAlphaComponent:0.5];
        _phoneNumberInputField.layer.masksToBounds = YES;
        _phoneNumberInputField.layer.cornerRadius = 4;
        _phoneNumberInputField.layer.borderColor = mainColor.CGColor;
        _phoneNumberInputField.layer.borderWidth = 1.0;
        _phoneNumberInputField.keyboardType = UIKeyboardTypePhonePad;
    }
    return  _phoneNumberInputField;
}


- (UIButton *)loginButton {
    if (_loginButton == nil) {
        _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginButton setTitle:LocalizedString(@"login_button_title") forState:UIControlStateNormal];
        [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _loginButton.backgroundColor = mainColor;
        _loginButton.layer.masksToBounds = YES;
        _loginButton.layer.cornerRadius = 4;
        
        [_loginButton addTarget:self action:@selector(loginButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _loginButton;
}

#pragma mark - layout subviews

- (void)buildLayout {
    [self.view addSubview:self.phoneNumberInputField];
    [self.phoneNumberInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(200);
        make.leading.equalTo(self.view.mas_leading).offset(100);
        make.trailing.equalTo(self.view.mas_trailing).offset(-100);
        make.height.mas_equalTo(44);
    }];
    
    [self.view addSubview:self.loginButton];
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.phoneNumberInputField.mas_bottom).offset(40);
        make.size.mas_equalTo(CGSizeMake(80, 44));
        make.centerX.equalTo(self.phoneNumberInputField);
    }];
}


#pragma  mark - actions
//登录
- (void)loginButtonClick:(UIButton *)button {
    if (self.phoneNumberInputField.text.length < 11) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"手机号不能低于11位"]];
        return;
    }
    button.enabled = NO;
    [RCGameService loginWithPhoneNumber:self.phoneNumberInputField.text
                             verifyCode:@"123456" deviceId: _deviceID()
                               userName:nil
                               portrait:nil
                          responseClass:[LoginResponse class]
                                success:^(id  _Nullable responseObject) {
        button.enabled = YES;
        LoginResponse *res = (LoginResponse *)responseObject;
        RCGameService.authorization = res.data.authorization;
        
        Log(@"network login success");
        
        [UserManager sharedManager].currentUser.userName = res.data.userName;
        [UserManager sharedManager].currentUser.userId = res.data.userId;
        [UserManager sharedManager].currentUser.token = res.data.imToken;
        [UserManager sharedManager].currentUser.authorization = res.data.authorization;
        
        if ([[UserManager sharedManager].currentUser save]) {
            Log(@"user info save success");
            [LaunchManager initSDKWithAppKey:AppKey imToken:res.data.imToken completion:^(BOOL success, RCConnectErrorCode code) {
                if (success) {
                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"连接融云成功，当前id%@", [UserManager sharedManager].currentUser.userId]];
                    Log("voice sdk initializ success");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.navigationController setViewControllers:@[self.homeViewController]];
                    });
                } else {
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"连接融云失败 code: %ld",code]];
                    Log("voice sdk initializ fail %ld",(long)code);
                }
            }];
        } else {
            [SVProgressHUD showErrorWithStatus:@"用户信息保存失败"];
        }
    } failure:^(NSError * _Nonnull error) {
        button.enabled = YES;
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"%@ code: %ld",LocalizedString(@"network_error"),(long)error.code]];
    }];
}


@end
