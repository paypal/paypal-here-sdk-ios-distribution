//
//  TransactionViewController.m
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/19/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "TransactionViewController.h"
#import "SettingsViewController.h"
#import "PaymentMethodViewController.h"
#import "RefundViewController.h"
#import "AuthorizedPaymentsViewController.h"
#import "STTransactionsTableViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>
#import "STAppDelegate.h"


#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad


#define kAPPLES			@"Apples"
#define kBANANAS		@"Bananas"
#define kORANGES		@"Oranges"
#define kSTRAWBERRIES	@"Strawberries"
#define kPRICE			@"Price"
#define kQUANTITY		@"Quantity"

@interface TransactionViewController ()
- (IBAction)onChargePressed:(id)sender;
- (IBAction)onSettingsPressed:(id)sender;
- (IBAction)onRefundsPressed:(id)sender;
- (IBAction)onViewAuthorizedSales:(id)sender;

@property (nonatomic, retain) IBOutlet UIButton *applesButton;
@property (nonatomic, retain) IBOutlet UIButton *orangesButton;
@property (nonatomic, retain) IBOutlet UIButton *bananasButton;
@property (nonatomic, retain) IBOutlet UIButton *strawberriesButton;

@property (weak, nonatomic) IBOutlet UITableView *shoppingCartTable;
@property (weak, nonatomic) IBOutlet UILabel *longPressExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;



@property (nonatomic, strong) NSArray *items;
@property (strong, nonatomic) NSMutableDictionary *store;
@property (nonatomic,strong) NSMutableDictionary *shoppingCart;

@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrApples;
@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrBananas;
@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrOranges;
@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrStrawberries;

@end

@implementation TransactionViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.items = @[kAPPLES, kBANANAS, kORANGES, kSTRAWBERRIES];
        
        self.store = [[NSMutableDictionary alloc] initWithDictionary:
                      @{kAPPLES:        [NSDecimalNumber decimalNumberWithString:@".95"],
                       kBANANAS:       [NSDecimalNumber decimalNumberWithString:@".50"],
                       kORANGES:       [NSDecimalNumber decimalNumberWithString:@".40"],
                       kSTRAWBERRIES:  [NSDecimalNumber decimalNumberWithString:@".25"]
                       }];
        
        self.shoppingCart = [[NSMutableDictionary alloc] initWithDictionary:
                             @{kAPPLES:        [NSDecimalNumber decimalNumberWithString:@"0.0"],
                               kBANANAS:       [NSDecimalNumber decimalNumberWithString:@"0.0"],
                               kORANGES:       [NSDecimalNumber decimalNumberWithString:@"0.0"],
                               kSTRAWBERRIES:  [NSDecimalNumber decimalNumberWithString:@"0.0"]
                               }];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
	self.title = @"New Transaction";

    
    self.shoppingCartTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.shoppingCartTable.bounces = NO;
    self.shoppingCartTable.allowsSelection = NO;
    [self.shoppingCartTable setDataSource:self];
    
    self.lpgrApples = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)];
    self.lpgrBananas = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)];
    self.lpgrOranges = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)];
    self.lpgrStrawberries = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)];


    self.lpgrApples.minimumPressDuration = 0.5;
    self.lpgrBananas.minimumPressDuration = 0.5;
    self.lpgrOranges.minimumPressDuration = 0.5;
    self.lpgrStrawberries.minimumPressDuration = 0.5;

    [self.applesButton addGestureRecognizer:self.lpgrApples];
    [self.bananasButton addGestureRecognizer:self.lpgrBananas];
    [self.orangesButton addGestureRecognizer:self.lpgrOranges];
    [self.strawberriesButton addGestureRecognizer:self.lpgrStrawberries];

    UIBarButtonItem *currentInvoicesButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(didPressViewTransactions:)];
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(didPressClearCart:)];

    self.navigationItem.rightBarButtonItems = @[clearButton, currentInvoicesButton];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Do we have a previous transaction?   Cancel it.
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    if (tm.hasActiveTransaction)
    {
        [tm cancelPayment];
    }
    
    
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    [_purchaseButton setTitle:appDelegate.paymentFlowIsAuthOnly ? @"Authorize Purchase" : @"Purchase" forState:UIControlStateNormal];

}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PPHInvoice *)getInvoiceFromShoppingCart:(NSMutableDictionary *)shoppingCart {
    PPHInvoice *invoice = [[PPHInvoice alloc] initWithCurrency:@"USD"];
    for (NSString *item in self.shoppingCart) {
        [invoice addItemWithId:item detailId:nil name:item quantity:shoppingCart[item] unitPrice:self.store[item] taxRate:nil taxRateName:nil];
    }
    return invoice;
}

- (double) sumShoppingCart
{
	double total = 0.0;
    
	for (NSString *item in self.shoppingCart) {
		total += [self.shoppingCart[item] doubleValue]*[self.store[item] doubleValue];
	}
    
	return total;
}

- (void) verifyInvoiceBeforePayment:(PPHInvoice *)invoice {
    if (invoice.subTotal.doubleValue < 0.01 && invoice.subTotal.doubleValue > -0.01) {
		[self showAlertWithTitle:@"Input Error" andMessage:@"You cannot specify amounts less than a penny."];
	}
    // Insert other verifications here
}

- (IBAction)onChargePressed:(id)sender {
    
    if (![PayPalHereSDK activeMerchant]) {
        [self showAlertWithTitle:@"Bad State!" andMessage:@"The merchant hasn't been created yet?   We can't use the SDK until the merchant exists."];
        return;
    }
    
    PPHInvoice *invoice = [self getInvoiceFromShoppingCart:self.shoppingCart];
    [self verifyInvoiceBeforePayment:invoice];
    
    // Begin the purchase and forward to payment method
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    [tm beginPayment];
    tm.currentInvoice = invoice;
    
    NSString *interfaceName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"PaymentMethodViewController_iPhone" : @"PaymentMethodViewController_iPad";
    
    PaymentMethodViewController *paymentMethod = [[PaymentMethodViewController alloc]
                                                  initWithNibName:interfaceName
                                                  bundle:nil];

    
    [self.navigationController pushViewController:paymentMethod animated:YES];
    
    
    //[self showAlertWithTitle:@"Please Swipe your Credit Card" andMessage:@"The PayPalHereSDK is now waiting for a card swipe to proceed."];
    
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:nil
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}




- (IBAction)onSettingsPressed:(id)sender {
    SettingsViewController *settings = [[SettingsViewController alloc]
                                        initWithNibName:@"SettingsViewController"
                                                 bundle:nil];
    
    [self.navigationController pushViewController:settings animated:YES];
}

- (IBAction)onRefundsPressed:(id)sender
{
    RefundViewController * refund =  [[RefundViewController alloc]
                         initWithNibName:@"RefundViewController"
                                  bundle:nil];
    
    [self.navigationController pushViewController:refund animated:YES];
    
}

- (IBAction)onViewAuthorizedSales:(id)sender
{
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];

    AuthorizedPaymentsViewController * vc =  [[AuthorizedPaymentsViewController alloc]
                                      initWithNibName:@"AuthorizedPaymentsViewController"
                                      bundle:nil
                                    transactionRecords:appDelegate.authorizedRecords];
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)didPressViewTransactions:(id)sender {
    STTransactionsTableViewController *vc = [[STTransactionsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)didPressAddItem:(id)sender {
    NSString *itemClicked;
    if (sender == self.applesButton) {
        itemClicked = kAPPLES;
    } else if (sender == self.bananasButton) {
        itemClicked = kBANANAS;
    } else if (sender == self.orangesButton) {
        itemClicked = kORANGES;
    } else if (sender == self.strawberriesButton) {
        itemClicked = kSTRAWBERRIES;
    } else {
        NSLog(@"There is another unidentified target to this method");
    }
    NSDecimalNumber *incremented = [self.shoppingCart[itemClicked] decimalNumberByAdding:[NSDecimalNumber one]];
    [self.shoppingCart setObject:incremented forKey:itemClicked];
    
    [self.shoppingCartTable reloadData];
}

-(IBAction)buttonLongPressed:(id)sender {
    if (sender == self.lpgrApples) {
        [self.shoppingCart setObject:[NSDecimalNumber zero] forKey:kAPPLES];
    } else if (sender == self.lpgrBananas) {
        [self.shoppingCart setObject:[NSDecimalNumber zero] forKey:kBANANAS];
    } else if (sender == self.lpgrOranges) {
        [self.shoppingCart setObject:[NSDecimalNumber zero] forKey:kORANGES];
    } else if (sender == self.lpgrStrawberries) {
        [self.shoppingCart setObject:[NSDecimalNumber zero] forKey:kSTRAWBERRIES];
    }
    [self.shoppingCartTable reloadData];
}

- (IBAction)didPressClearCart:(id)sender {
    self.shoppingCart = [[NSMutableDictionary alloc] initWithDictionary:
                         @{kAPPLES:        [NSDecimalNumber decimalNumberWithString:@"0.0"],
                           kBANANAS:       [NSDecimalNumber decimalNumberWithString:@"0.0"],
                           kORANGES:       [NSDecimalNumber decimalNumberWithString:@"0.0"],
                           kSTRAWBERRIES:  [NSDecimalNumber decimalNumberWithString:@"0.0"]
                           }];
    [self.shoppingCartTable reloadData];
}

#pragma mark - UITableViewDataSource callbacks
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell && IS_IPAD) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    } else if (!cell && !IS_IPAD) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < self.items.count) {
        NSString* item = self.items[indexPath.row];
        NSString *format = (indexPath.row == 0) ?  @"%@ ($%0.2f)\t\t\t\t%d" : (indexPath.row == 3) ? @"%@ ($%0.2f)\t\t%d" : @"%@ ($%0.2f)\t\t\t%d";
        cell.textLabel.text = [NSString stringWithFormat:format, item, [(NSDecimalNumber *)self.store[item] doubleValue], [self.shoppingCart[item] intValue]];
		cell.textLabel.textAlignment = NSTextAlignmentLeft;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"TOTAL: $%0.2f", [self sumShoppingCart]];
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    
	return cell;
}


@end

