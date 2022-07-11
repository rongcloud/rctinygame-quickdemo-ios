
#import "RWTableView.h"


@interface RWTableView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, copy) RWTableViewDidSelectRowAtIndexPathBlock     didSelectRowAtIndexPathCb;
@property (nonatomic, copy) RWTableViewHeightForRowAtIndexPathBlock     heightForRowAtIndexPathCb;
@property (nonatomic, copy) RWTableViewNumberOfSectionsInTableViewBlock numberOfSectionsInTableViewCb;
@property (nonatomic, copy) RWTableViewNumberOfRowsInSectionBlock       numberOfRowsInSectionCb;
@property (nonatomic, copy) RWTableViewCellForRowAtIndexPathBlock       cellForRowAtIndexPathCb;
@property (nonatomic, copy) RWTableViewHeightForHeaderInSection         heightForHeaderInSectionCb;
@property (nonatomic, copy) RWTableViewViewForHeaderInSection           viewForHeaderInSectionCb;
@end

@implementation RWTableView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
    }
    return self;
}

#pragma mark- =======Public=======
- (void)setNumberOfSectionsInTableViewCb:(RWTableViewNumberOfSectionsInTableViewBlock)numberOfSectionsInTableViewCb
                 numberOfRowsInSectionCb:(RWTableViewNumberOfRowsInSectionBlock)numberOfRowsInSectionCb
               heightForRowAtIndexPathCb:(RWTableViewHeightForRowAtIndexPathBlock)heightForRowAtIndexPathCb
                 cellForRowAtIndexPathCb:(RWTableViewCellForRowAtIndexPathBlock)cellForRowAtIndexPathCb
               didSelectRowAtIndexPathCb:(RWTableViewDidSelectRowAtIndexPathBlock)didSelectRowAtIndexPathCb
              heightForHeaderInSectionCb:(RWTableViewHeightForHeaderInSection)heightForHeaderInSectionCb
                viewForHeaderInSectionCb:(RWTableViewViewForHeaderInSection)viewForHeaderInSectionCb{
    _numberOfSectionsInTableViewCb = numberOfSectionsInTableViewCb;
    _numberOfRowsInSectionCb = numberOfRowsInSectionCb;
    _heightForRowAtIndexPathCb = heightForRowAtIndexPathCb;
    _cellForRowAtIndexPathCb = cellForRowAtIndexPathCb;
    _didSelectRowAtIndexPathCb = didSelectRowAtIndexPathCb;
    _heightForHeaderInSectionCb = heightForHeaderInSectionCb;
    _viewForHeaderInSectionCb = viewForHeaderInSectionCb;
}

#pragma mark- =======UITableViewDelegate=======
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.didSelectRowAtIndexPathCb) {
        self.didSelectRowAtIndexPathCb(tableView, indexPath);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.heightForRowAtIndexPathCb) {
        return self.heightForRowAtIndexPathCb(tableView, indexPath);
    }
    return 0;
}

#pragma mark- =======UITableViewDataSource=======
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.numberOfSectionsInTableViewCb) {
        return self.numberOfSectionsInTableViewCb(tableView);
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.numberOfRowsInSectionCb) {
        return self.numberOfRowsInSectionCb(tableView, section);
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.heightForHeaderInSectionCb) {
        return self.heightForHeaderInSectionCb(tableView, section);
    }
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.cellForRowAtIndexPathCb) {
        return self.cellForRowAtIndexPathCb(tableView, indexPath);
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.viewForHeaderInSectionCb) {
        return self.viewForHeaderInSectionCb(tableView, section);
    }
    return nil;
}


@end
