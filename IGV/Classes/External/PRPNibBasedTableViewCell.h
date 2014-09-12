#import <UIKit/UIKit.h>

@interface PRPNibBasedTableViewCell : UITableViewCell {}

+ (UINib *)nib;
+ (NSString *)nibName;

+ (NSString *)cellIdentifier;
+ (id)cellForTableView:(UITableView *)tableView fromNib:(UINib *)nib;

@end