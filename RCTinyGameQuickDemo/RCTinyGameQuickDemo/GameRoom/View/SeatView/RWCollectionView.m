
#import "RWCollectionView.h"


@interface RWCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, copy) RWCollectionViewDidSelectItemAtIndexPathBlock didSelectItemAtIndexPathCb;
@property (nonatomic, copy) RWCollectionViewNumberOfSectionsInCollectionViewBlock numberOfSectionsInCollectionViewCb;
@property (nonatomic, copy) RWCollectionViewNumberOfItemsInSectionBlock numberOfItemsInSectionCb;
@property (nonatomic, copy) RWCollectionViewCellForItemAtIndexPathBlock cellForItemAtIndexPathCb;
@end

@implementation RWCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

#pragma mark- =======Public=======
- (void)setDidSelectItemAtIndexPathCb:(RWCollectionViewDidSelectItemAtIndexPathBlock)didSelectItemAtIndexPathCb
   numberOfSectionsInCollectionViewCb:(RWCollectionViewNumberOfSectionsInCollectionViewBlock)numberOfSectionsInCollectionViewCb
             numberOfItemsInSectionCb:(RWCollectionViewNumberOfItemsInSectionBlock)numberOfItemsInSectionCb
             cellForItemAtIndexPathCb:(RWCollectionViewCellForItemAtIndexPathBlock)cellForItemAtIndexPathCb {
    _didSelectItemAtIndexPathCb = didSelectItemAtIndexPathCb;
    _numberOfSectionsInCollectionViewCb = numberOfSectionsInCollectionViewCb;
    _numberOfItemsInSectionCb = numberOfItemsInSectionCb;
    _cellForItemAtIndexPathCb = cellForItemAtIndexPathCb;
}


#pragma mark- UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.didSelectItemAtIndexPathCb) {
        self.didSelectItemAtIndexPathCb(collectionView, indexPath);
    }
}

#pragma mark- =======UICollectionViewDataSource=======
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.numberOfSectionsInCollectionViewCb) {
        return self.numberOfSectionsInCollectionViewCb(collectionView);
    }
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.numberOfItemsInSectionCb) {
        return self.numberOfItemsInSectionCb(collectionView, section);
    }
    return 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.cellForItemAtIndexPathCb) {
        return self.cellForItemAtIndexPathCb(collectionView, indexPath);
    }
    return nil;
}


@end
