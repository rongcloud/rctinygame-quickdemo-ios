
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RWCollectionViewDidSelectItemAtIndexPathBlock)(UICollectionView *collectionView, NSIndexPath *indexPath);
typedef NSInteger (^RWCollectionViewNumberOfSectionsInCollectionViewBlock)(UICollectionView *collectionView);
typedef NSInteger (^RWCollectionViewNumberOfItemsInSectionBlock)(UICollectionView *collectionView, NSInteger section);
typedef __kindof UICollectionViewCell * (^RWCollectionViewCellForItemAtIndexPathBlock)(UICollectionView *collectionView, NSIndexPath *indexPath);

@interface RWCollectionView : UICollectionView

- (void)setDidSelectItemAtIndexPathCb:(RWCollectionViewDidSelectItemAtIndexPathBlock)didSelectItemAtIndexPathCb
   numberOfSectionsInCollectionViewCb:(RWCollectionViewNumberOfSectionsInCollectionViewBlock)numberOfSectionsInCollectionViewCb
             numberOfItemsInSectionCb:(RWCollectionViewNumberOfItemsInSectionBlock)numberOfItemsInSectionCb
             cellForItemAtIndexPathCb:(RWCollectionViewCellForItemAtIndexPathBlock)cellForItemAtIndexPathCb;

@end

NS_ASSUME_NONNULL_END
