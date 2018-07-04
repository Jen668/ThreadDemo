//
//  ViewController.m
//  ThreadDemo
//
//  Created by 张诗健 on 2018/6/3.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "ViewController.h"
#import <pthread/pthread.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


/*
 * 创建线程
 */
- (IBAction)creatThreadA:(id)sender
{
    // 创建一个线程对象
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadAMainMethod) object:nil];
    
    // 设置线程名称（方便调试）
    thread.name = @"threadA";
    
    // 设置线程的优先级，默认为0.5
    [thread setThreadPriority:0.6];
    
    // 设置可以从任何位置访问的线程局部存储（例如，我们可以使用它通过线程的run loop的多次迭代来保存状态信息）
    [thread.threadDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"ThreadShouldExitNow"];
    
    // 启动线程
    [thread start];
}


- (IBAction)creatThreadB:(id)sender
{
    // 使用类方法直接分离一个新线程
    [NSThread detachNewThreadSelector:@selector(threadBMainMethod) toTarget:self withObject:nil];
}



- (IBAction)creatThreadC:(id)sender
{
    pthread_attr_t attr;
    pthread_t posixThreadID;
    int returnVal;
    
    returnVal = pthread_attr_init(&attr);
    
    assert(!returnVal);
    
    // 设置线程的分离状态
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    
    assert(!returnVal);
    
    // 创建线程
    int threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, NULL);
    
    returnVal = pthread_attr_destroy(&attr);
    
    assert(!returnVal);
    
    if (threadError != 0)
    {
        // report an error
    }
    
}


#pragma mark - main function of thread
- (void)threadAMainMethod
{
    NSLog(@"线程A");
    
    for (NSInteger i = 0; i < 100; i++)
    {
        // 创建自动释放池，以便及时释放对象资源。否则，这些对象会一直保留，直到线程退出。
        @autoreleasepool
        {
            NSString *str = [NSString stringWithFormat:@"%ld",i];
            NSLog(@"%@",str);
        }
    }
    
    NSLog(@"线程A退出");
}

- (void)threadBMainMethod
{
    NSLog(@"线程B");
    
    for (NSInteger i = 0; i < 10; i++)
    {
        NSLog(@"%ld",i);
    }
    
    NSLog(@"线程B退出");
}


void* PosixThreadMainRoutine(void* data)
{
    // do some work here
    NSLog(@"线程C");
    
    for (NSInteger i = 0; i < 10; i++)
    {
        NSLog(@"%ld",i);
    }
    
    NSLog(@"线程C退出");
    
    return NULL;
}



/*
 * 配置 Run Loop
 */
- (IBAction)launchThreadA:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadAMainRoutline) toTarget:self withObject:nil];
}

- (IBAction)launchThreadB:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadBMainRoutline) toTarget:self withObject:nil];
}


- (void)threadAMainRoutline
{
    NSLog(@"进入线程A");
    
    NSThread *thread = [NSThread currentThread];
    
    [thread.threadDictionary setObject:[NSNumber numberWithInteger:0] forKey:@"repeatCount"];
    
    // 获取当前线程的run loop对象
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    // 创建一个run loop观察者，并将其与run loop关联起来。
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
    
    if (observer)
    {
        CFRunLoopRef cfLoop = [runLoop getCFRunLoop];
        
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }
    
    NSInteger loopCount = 20;
    
    // 使用此方法创建定时器时，会自动附加定时器源到当前线程的run loop上。
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    
    while (loopCount)
    {
        // 进入事件处理循环
        //[runLoop run];
        
        // 进入事件处理循环，并在指定的日期自动退出事件处理循环。
        //[runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
        
        // 以特定的模式进入事件处理循环，并在指定的日期自动退出事件处理循环。
        // 如果启动run loop并处理输入源或达到指定的超时值，则返回YES; 否则，如果无法启动run loop，则返回NO。
        BOOL done = [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];

        if (!done)
        {
            NSLog(@"启动 run loop 失败!!!");
        }
        
        loopCount--;
    }
    
    NSLog(@"退出线程A");
}


void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"进入 run loop");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"定时器即将触发");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"不是基于端口的输入源即将触发");
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"线程即将进入休眠状态");
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"线程刚被唤醒");
            break;
        case kCFRunLoopExit:
            NSLog(@"退出 run loop");
            break;
        default:
            break;
    }
}

- (void)timerFire:(NSTimer *)timer
{
    NSThread *thread = [NSThread currentThread];
    
    NSInteger repeatCount = [[thread.threadDictionary objectForKey:@"repeatCount"] integerValue];
    
    repeatCount++;
    
    [thread.threadDictionary setObject:[NSNumber numberWithInteger:repeatCount] forKey:@"repeatCount"];
    
    NSLog(@"============= %ld",repeatCount);
}


- (void)threadBMainRoutline
{
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
