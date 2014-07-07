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
#import "CCCFSPaymentMethodViewController.h"
#import "STAppDelegate.h"

#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad


#define kAPPLES			@"Apples"
#define kBANANAS		@"Bananas"
#define kORANGES		@"Oranges"
#define kSTRAWBERRIES	@"Strawberries"
#define kPRICE			@"Price"
#define kQUANTITY		@"Quantity"

@interface TransactionViewController () <InvoicesProtocal>
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
@property (weak, nonatomic) IBOutlet UIButton *refundButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSMutableDictionary *store;
@property (nonatomic, strong) NSMutableDictionary *shoppingCart;

@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrApples;
@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrBananas;
@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrOranges;
@property (nonatomic,strong) UILongPressGestureRecognizer *lpgrStrawberries;

@property kSAFlow flow;
@end

@implementation TransactionViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil aDelegate: (id) delegate
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
                             @{kAPPLES:        [NSDecimalNumber zero],
                               kBANANAS:       [NSDecimalNumber zero],
                               kORANGES:       [NSDecimalNumber zero],
                               kSTRAWBERRIES:  [NSDecimalNumber zero]
                               }];
        
        self.delegate = delegate;
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

    self.purchaseButton.layer.cornerRadius = 10;
    self.captureButton.layer.cornerRadius = 10;
    self.refundButton.layer.cornerRadius = 10;
    self.settingsButton.layer.cornerRadius = 10;
    
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


- (double) sumShoppingCart
{
	double total = 0.0;
    
	for (NSString *item in self.shoppingCart) {
		total += [self.shoppingCart[item] doubleValue]*[self.store[item] doubleValue];
	}
    
	return total;
}


- (PPHInvoice *)getInvoiceFromShoppingCart{
    PPHInvoice *invoice = [[PPHInvoice alloc] initWithCurrency:@"USD"];
    
    NSString *taxRate = [[NSUserDefaults standardUserDefaults] objectForKey:@"taxRate"];
    NSDecimalNumber *taxRateNumber;
    if (taxRate) {
        taxRateNumber = [NSDecimalNumber decimalNumberWithString:taxRate];
    } else {
        taxRateNumber = [NSDecimalNumber decimalNumberWithString:@".10"];
    }

    for (NSString *item in self.shoppingCart) {
        [invoice addItemWithId:item detailId:nil name:item quantity:self.shoppingCart[item] unitPrice:self.store[item] taxRate:taxRateNumber taxRateName:@"taxRate"];
    }

    return invoice;
}

- (IBAction)onChargePressed:(id)sender {
    PPHInvoice *invoice = [self getInvoiceFromShoppingCart];
    [self purchaseWithInvoice:invoice];
}

- (void) purchaseWithInvoice:(PPHInvoice *)invoice {
    kSAFlow currentFlow = [self.delegate purchase:invoice];
    
    UIViewController *paymentMethodVC = nil;
    switch (currentFlow) {
        case kSAFS: {
            // Choose Payment method
            NSString *interfaceName = (IS_IPAD) ? @"PaymentMethodViewController_iPad" : @"PaymentMethodViewController_iPhone";
            paymentMethodVC = [[PaymentMethodViewController alloc] initWithNibName:interfaceName bundle:nil];
            break;
        }
        case kSACCC: {
            // Choose Payment method
            NSString *interfaceName = @"CCCFSPaymentMethodViewController";
            paymentMethodVC = [[CCCFSPaymentMethodViewController alloc] initWithNibName:interfaceName bundle:nil];
            break;
        }
        case kSAError:
            NSLog(@"Error! Bad Flow");
            return;
        default:
            return;
    }
    
    [self.navigationController pushViewController:paymentMethodVC animated:YES];
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
    STTransactionsTableViewController *vc = [[STTransactionsTableViewController alloc] initWithStyle:UITableViewStylePlain andDelegate:self];
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
        return;
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
                         @{kAPPLES:        [NSDecimalNumber zero],
                           kBANANAS:       [NSDecimalNumber zero],
                           kORANGES:       [NSDecimalNumber zero],
                           kSTRAWBERRIES:  [NSDecimalNumber zero]
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

