//
//  AuthorizedTransactionsTableViewController.m
//  RetailSDKTestApp
//
//  Created by Singeetham, Sreepada on 6/12/17.
//  Copyright © 2017 PayPal. All rights reserved.
//

#import "AuthorizedTransactionsTableViewController.h"
#import "CaptureViewController.h"

@interface AuthorizedTransactionsTableViewController ()

@end

@implementation AuthorizedTransactionsTableViewController
NSMutableArray *tableData;
NSMutableArray *tableDataAsResponseObjects;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tableData = [[NSMutableArray alloc] init];
    tableDataAsResponseObjects = [[NSMutableArray alloc] init];
    NSString *startTimeString = @"2017-06-02T00:00:01";
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSDate *startTime = [formatter1 dateFromString:startTimeString];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd HH:mm"];
    NSLog(@"created the startTime date object: %@", startTime);
    [PayPalRetailSDK retrieveAuthorizedTransaction:startTime endTime:nil pageSize:nil nextPageToken:nil completionHandler:^(PPRetailError *error, PPRetailRetrieveAuthorizedTransactionResponse *response) {
        
        [response.listOfAuths enumerateObjectsUsingBlock:^(PPRetailAuthorizedTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //            NSLog(@"the response object is %@");
            NSString *line1 = [@"authorizatoinId: " stringByAppendingString:[obj authorizationId]];
            NSString *line2 = [@"status: " stringByAppendingString:[obj status]];
            NSString *line3 = [@"netAuthorizedAmount: " stringByAppendingString:[NSString stringWithFormat:@"%@", [obj netAuthorizedAmount]]];
            NSString *line4 = [@"timeCreated: " stringByAppendingString:[formatter stringFromDate:[obj timeCreated]]];
            NSString *line5 = [@"currency: " stringByAppendingString:[obj currency]];
            NSString *line6 = @"";
            if ([obj detailedStatus]) {
                line6 = [@"detailedStatus: " stringByAppendingString:[obj detailedStatus]];
            }
            
            NSString *rLine1 = [@[line3, line5, line4] componentsJoinedByString:@" "];
            NSString *rLine2 = [@[line1, line2] componentsJoinedByString:@" "];
            
            NSString *resultantString = [@[rLine1, rLine2, line6] componentsJoinedByString:@"\n"];
            [tableData addObject:resultantString];
            [tableDataAsResponseObjects addObject:obj];
            [self.tableContent reloadData];
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableIdentifier = @"authorizedTransactions";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier forIndexPath:indexPath];
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
    }
    
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"captureAuthorization" sender:self];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"captureAuthorization"]) {
        NSLog(@"performing a segue with identifier %@", [segue identifier]);
        CaptureViewController *viewController = [segue destinationViewController];
        NSLog(@"the path index is: %ld", [self.tableContent indexPathForSelectedRow].row);
        NSLog(@"the object at index is: %@", [[tableDataAsResponseObjects objectAtIndex:0] authorizationId]);
        NSLog(@"the line at that index is: %@", [tableData objectAtIndex:0]);
        viewController.authorizationFromSegue = [tableDataAsResponseObjects objectAtIndex:[self.tableContent indexPathForSelectedRow].row];
        NSLog(@"the authorization ID being set is %@", viewController.authorizationFromSegue.authorizationId);
    }
}


@end
