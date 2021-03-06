//
//  VideoFilterVC.m
//  LanSongEditor_all
//
//  Created by sno on 17/1/1.
//  Copyright © 2017年 lansongtech. All rights reserved.
//

#import "FilterRealTimeDemoVC.h"
#import "LanSongUtils.h"
#import "FilterTpyeList.h"


@interface FilterRealTimeDemoVC ()
{
    
    DrawPadPreview *drawpad;
    
    NSString *dstPath;
    NSString *dstTmpPath;
    
    NSURL *sampleURL;
    
    VideoPen *mVideoPen;
    
    FilterTpyeList *filterListVC;
    BOOL  isSelectFilter;
    
    CGFloat  drawPadWidth;
    CGFloat  drawPadHeight;
    NSTimer *testTimer;
}
@end

@implementation FilterRealTimeDemoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor whiteColor];
    
    
    
    dstTmpPath = [SDKFileUtil genFileNameWithSuffix:@"mp4"];
    dstPath = [SDKFileUtil genFileNameWithSuffix:@"mp4"];
     sampleURL = [[NSBundle mainBundle] URLForResource:@"ping20s" withExtension:@"mp4"];
    
    MediaInfo *info=[[MediaInfo alloc] initWithPath:[SDKFileUtil urlToFileString:sampleURL]];
    
    if ([info prepare] && [info hasVideo]) {
        
        drawPadWidth=info.vWidth;  //把画板还采用原来的尺寸.
        drawPadHeight=info.vHeight;
        
    }else{
        return ;
    }
    /*
     step1:第一步: 创建一个画板,(主要参数为:画板宽度高度,码率,保存路径,预览View)
     */
    int  drawPadBitRate=2000*1000;
   
    drawpad=[[DrawPadPreview alloc] initWithWidth:drawPadWidth height:drawPadHeight bitrate:drawPadBitRate dstPath:dstTmpPath];
    
    CGSize size=self.view.frame.size;
  
    
    /*
     这里采用宽度为屏幕宽度, 调整高度值,使它宽高比等于画板的宽高比, 实际您可以自由分配预览的View宽高, 
     但为了画面不至于变形, 建议预览的宽高和设置的画板宽高成比例关系.比如画板的宽高比是16:9,则DrawPadView的宽高比也是16:9
     */
    DrawPadView *filterView=[[DrawPadView alloc] initWithFrame:CGRectMake(0, 60, size.width,size.width*(drawPadHeight/drawPadWidth))];
    
    [self.view addSubview: filterView];
    [drawpad setDrawPadPreView:filterView];
    
    
    /*
     
     第二步:增加各种图层,这里先增加一个背景图片,然后再增加视频图层
     
     */
    //您可以增加个背景图片做为图层.
//    UIImage *imag=[UIImage imageNamed:@"p640x1136"];
//    [drawpad addBitmapPen:imag];
    
    
    //增加主视频图层
     GPUImageFilter *filter= (GPUImageFilter *)[[GPUImageSepiaFilter alloc] init];
    mVideoPen=[drawpad addMainVideoPen:[SDKFileUtil urlToFileString:sampleURL] filter:filter];
    
    /*
     第三步: 设置进度回调和完成回调,开始执行.
     */
    __weak typeof(self) weakSelf = self;
    [drawpad setOnProgressBlock:^(CGFloat currentPts) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.labProgress.text=[NSString stringWithFormat:@"当前进度 %f",currentPts];
            
        });
    }];
    
    //设置完成后的回调
    [drawpad setOnCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf addAudio];
            [weakSelf showIsPlayDialog];
            
        });
    }];
    
    //开始工作
    if([drawpad startDrawPad]==NO)
    {
        NSLog(@"DrawPad容器线程执行失败, 请联系我们!");
    }
    //---------一下是ui操作.-------------------------------------------------
    testTimer=[NSTimer scheduledTimerWithTimeInterval: 1   /*10秒钟触发一次,可以有小数,比如0.1*/
                                               target: self
                                             selector: @selector(timerSelector:)
                                             userInfo: nil
                                              repeats: NO];
    
    _labProgress=[[UILabel alloc] init];
    _labProgress.textColor=[UIColor redColor];
    
      CGFloat padding=size.height*0.01;
    [self.view addSubview:_labProgress];
    
    [_labProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(filterView.mas_bottom).offset(padding);
        make.centerX.mas_equalTo(filterView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(size.width, 40));
    }];
    
    UISlider *slide=[self createSlide:_labProgress min:0.0f max:1.0f value:0.5f tag:101 labText:@"效果调节 "];
    
    UIButton *btnFilter=[[UIButton alloc] init];
    
    
    [btnFilter setTitle:@"请选择滤镜效果" forState:UIControlStateNormal];
    [btnFilter setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    btnFilter.backgroundColor=[UIColor whiteColor];
    
    [btnFilter addTarget:self action:@selector(doButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnFilter];
    
    [btnFilter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(slide.mas_bottom).offset(padding);
        make.centerX.mas_equalTo(filterView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(180, 80));
    }];
    
    
    filterListVC=[[FilterTpyeList alloc] initWithNibName:nil bundle:nil];
    filterListVC.filterSlider=slide;
    filterListVC.filterPen=mVideoPen;
    isSelectFilter=NO;

}
-(void)timerSelector: (NSTimer *) timer
{
}
-(void)stopTestTimer
{
    if (testTimer!=NULL) {
        [testTimer invalidate];
        testTimer=NULL;
    }
}
-(void)doButtonClicked:(UIView *)sender
{
    isSelectFilter=YES;
     [self.navigationController pushViewController:filterListVC animated:YES];
  
    
}
-(void)viewDidAppear:(BOOL)animated
{
    isSelectFilter=NO;
}
-(void)viewDidDisappear:(BOOL)animated
{
    if (drawpad!=nil && isSelectFilter==NO) {
        [drawpad stopDrawPad];
    }
    [self stopTestTimer];
}
/*
 
 滑动 效果调节后的相应

 */
- (void)slideChanged:(UISlider*)sender
{
    switch (sender.tag) {
        case 101:  //weizhi
            [filterListVC updateFilterFromSlider:sender];
            break;
        default:
            break;
    }
}
-(void)addAudio
{
    if ([SDKFileUtil fileExist:dstTmpPath]) {
        [VideoEditor drawPadAddAudio:[SDKFileUtil urlToFileString: sampleURL] newMp4:dstTmpPath dstFile:dstPath];
    }else{
        dstPath=dstTmpPath;
    }
}
-(void)showIsPlayDialog
{
    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:@"提示" message:@"视频已经处理完毕,是否需要预览" delegate:self cancelButtonTitle:@"预览" otherButtonTitles:@"返回", nil];
    [alertView show];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        
        [LanSongUtils startVideoPlayerVC:self.navigationController dstPath:dstPath];
    }else {  //返回
        
    }
}

-(void)dealloc
{
    filterListVC=nil;
    mVideoPen=nil;
    dstPath=nil;
    if([SDKFileUtil fileExist:dstPath]){
        [SDKFileUtil deleteFile:dstPath];
    }
    if([SDKFileUtil fileExist:dstTmpPath]){
        [SDKFileUtil deleteFile:dstTmpPath];
    }
    NSLog(@"Filter real time demo dealloc....");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/**
 初始化一个slide 返回这个UISlider对象
 */
-(UISlider *)createSlide:(UIView *)topView  min:(CGFloat)min max:(CGFloat)max  value:(CGFloat)value tag:(int)tag labText:(NSString *)text;
{
    UILabel *labPos=[[UILabel alloc] init];
    labPos.text=text;
    
    UISlider *slideFilter=[[UISlider alloc] init];
    
    slideFilter.maximumValue=max;
    slideFilter.minimumValue=min;
    slideFilter.value=value;
    slideFilter.continuous = YES;
    slideFilter.tag=tag;
    
    [slideFilter addTarget:self action:@selector(slideChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    CGSize size=self.view.frame.size;
    CGFloat padding=size.height*0.01;
    
    [self.view addSubview:labPos];
    [self.view addSubview:slideFilter];
    
    
    [labPos mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(topView.mas_bottom).offset(padding);
        make.left.mas_equalTo(self.view.mas_left);
        make.size.mas_equalTo(CGSizeMake(100, 40));
    }];
    
    [slideFilter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(labPos.mas_centerY);
        make.left.mas_equalTo(labPos.mas_right).offset(padding);
        make.right.mas_equalTo(self.view.mas_right).offset(-padding);
    }];
    return slideFilter;
}
@end

