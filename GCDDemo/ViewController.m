//
//  ViewController.m
//  GCDDemo
//
//  Created by yxf on 2018/3/19.
//  Copyright © 2018年 yxf. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self gcd_1];
//    [self targetQueue];
//    [self apply];
//    [self group];
//    [self semaphore];
//    [self barrier];
    [self resumeSuspend];
}

/*
 同步执行是不开辟线程，就在当前线程中执行。异步执行是开辟新的线程，在新线程中执行。
 队列用于保存各种操作，本着先进先出的原则进行。
 不同的是串行队列，严格按照先进先出的原则，只有上一个操作完成之后，才会开始下一个操作，此时开辟多条线程没有意义。
 而异步队列，会根据硬件能力开辟多条线程，当某个操作完成，会把队列中最前面的操作添加进该线程。
 因此只有异步执行并行队列时，才会开辟多条线程。
 并行队列和异步执行充分利用了cpu的性能，提高了效率，但在一定程度上增加了消耗。
 */

-(void)gcd_1{
    //串行队列
    dispatch_queue_t queue_1 = dispatch_queue_create("serial_queue", DISPATCH_QUEUE_SERIAL);
    
    //同步执行
//    for (int i=0; i<10; i++) {
//        dispatch_sync(queue_1, ^{
//            NSLog(@"--同步执行串行队列--%zd",i);
//        });
//    }
//
//    //异步执行
//    for (int i=0; i<100; i++) {
//        dispatch_async(queue_1, ^{
//            NSLog(@"--异步执行串行队列--%zd",i);
//        });
//    }
    
    for (int i=0; i<10; i++) {
        dispatch_sync(queue_1, ^{
            NSLog(@"--------------同步执行串行队列------------%zd",i);
            for (int j=0; j<100; j++) {
                dispatch_async(queue_1, ^{
                    NSLog(@"--异步执行串行队列--i:%zd,j:%zd",i,j);
                });
            }
        });
    }
    
}

-(void)getQueue{

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    
    //主队列的获取方法:主队列是串行队列，主队列中的任务都将在主线程中执行
    dispatch_queue_t mainqueue = dispatch_get_main_queue();
    
    //串行队列的创建方法:第一个参数表示队列的唯一标识,第二个参数用来识别是串行队列还是并发队列（若为NULL时，默认是DISPATCH_QUEUE_SERIAL）
    dispatch_queue_t seriaQueue = dispatch_queue_create("com.test.testQueue", DISPATCH_QUEUE_SERIAL);
    
    //并发队列的创建方法:第一个参数表示队列的唯一标识,第二个参数用来识别是串行队列还是并发队列（若为NULL时，默认是DISPATCH_QUEUE_SERIAL）
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.test.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    //全局并发队列的获取方法:第一个参数表示队列优先级,我们选择默认的好了,第二个参数flags作为保留字段备用,一般都直接填0
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    #pragma clang diagnostic pop
}

-(void)targetQueue{
    //dispatch_set_target_queue可以更改Dispatch Queue的执行优先级dispatch_queue_create函数生成的DisPatch Queue不管是Serial DisPatch Queue还是Concurrent Dispatch Queue,执行的优先级都与默认优先级的Global Dispatch queue相同,如果需要变更生成的Dispatch Queue的执行优先级则需要使用dispatch_set_target_queue函数。
    BOOL debug_1 = 0;
    if(debug_1){
        dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
        
        dispatch_async(serialQueue, ^{
            [NSThread sleepForTimeInterval:2];
            NSLog(@"serial queue - 1 -");
        });
        
        dispatch_queue_t gloabalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(gloabalQueue, ^{
            [NSThread sleepForTimeInterval:2];
            NSLog(@"gloabal queue - 2 -");
        });
        
        //第一个参数为要设置优先级的queue,第二个参数是参照物，即将第一个queue的优先级和第二个queue的优先级设置一样。
        dispatch_set_target_queue(serialQueue, gloabalQueue);
    }
    
    BOOL debug_2 = 1;
    if (debug_2) {
        NSLog(@"----start-----当前线程---%@",[NSThread currentThread]);
        
        dispatch_queue_t targetQueue = dispatch_queue_create("com.test.target_queue", DISPATCH_QUEUE_SERIAL);
        
        dispatch_queue_t queue1 = dispatch_queue_create("com.test.queue1", DISPATCH_QUEUE_SERIAL);
        
        dispatch_queue_t queue2 = dispatch_queue_create("com.test.queue2", DISPATCH_QUEUE_CONCURRENT);
        
        dispatch_set_target_queue(queue1, targetQueue);
        
        dispatch_set_target_queue(queue2, targetQueue);
        
        //指定一个异步任务
        dispatch_async(queue1, ^{
            NSLog(@"----执行第一个任务---当前线程%@",[NSThread currentThread]);
            [NSThread sleepForTimeInterval:2];
        });
        
        //指定一个异步任务
        dispatch_async(queue2, ^{
            NSLog(@"----执行第二个任务---当前线程%@",[NSThread currentThread]);
            [NSThread sleepForTimeInterval:2];
        });
        
        //指定一个异步任务
        dispatch_async(queue2, ^{
            NSLog(@"----执行第三个任务---当前线程%@",[NSThread currentThread]);
            [NSThread sleepForTimeInterval:2];
        });
        
        NSLog(@"----end-----当前线程---%@",[NSThread currentThread]);
    }
}

//快速遍历方法，可以替代for循环的函数。dispatch_apply按照指定的次数将指定的任务追加到指定的队列中，并等待全部队列执行结束。
//会创建新的线程，并发执行
-(void)apply{
    NSLog(@"----start-----当前线程---%@",[NSThread currentThread]);
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_apply(100, globalQueue, ^(size_t index) {
        //此时index的值不一定有序排列
        NSLog(@"执行第%zd次的任务---%@",index, [NSThread currentThread]);
    });
    
    NSLog(@"----end-----当前线程---%@",[NSThread currentThread]);
}

//队列组:当我们遇到需要异步下载3张图片，都下载完之后再拼接成一个整图的时候，就需要用到gcd队列组。
//队列组中操作的顺序不确定
-(void)group{
    NSLog(@"----start-----当前线程---%@",[NSThread currentThread]);
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 第一个任务
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----执行第一个任务---当前线程%@",[NSThread currentThread]);
        
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 第二个任务
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----执行第二个任务---当前线程%@",[NSThread currentThread]);
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 第三个任务
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----执行第三个任务---当前线程%@",[NSThread currentThread]);
    });
    
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----执行最后的汇总任务---当前线程%@",[NSThread currentThread]);
    });
    
    //若想执行完上面的任务再走下面这行代码可以加上下面这句代码
    
    // 等待上面的任务全部完成后，往下继续执行（会阻塞当前线程）
    //    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"----end-----当前线程---%@",[NSThread currentThread]);
}

//信号量
//总结:信号量设置的是2，在当前场景下，同一时间内执行的线程就不会超过2，先执行2个线程，等执行完一个，下一个会开始执行。
-(void)semaphore{
    NSLog(@"----start-----当前线程---%@",[NSThread currentThread]);
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //任务1
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"----开始执行第一个任务---当前线程%@",[NSThread currentThread]);
        
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----结束执行第一个任务---当前线程%@",[NSThread currentThread]);
        
        dispatch_semaphore_signal(semaphore);
    });
    
    //任务2
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"----开始执行第二个任务---当前线程%@",[NSThread currentThread]);
        
        [NSThread sleepForTimeInterval:1];
        
        NSLog(@"----结束执行第二个任务---当前线程%@",[NSThread currentThread]);
        
        dispatch_semaphore_signal(semaphore);
    });
    
    //任务3
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"----开始执行第三个任务---当前线程%@",[NSThread currentThread]);
        
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----结束执行第三个任务---当前线程%@",[NSThread currentThread]);
        
        dispatch_semaphore_signal(semaphore);
    });
    
    
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"----开始执行第4个任务---当前线程%@",[NSThread currentThread]);
        
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----结束执行第4个任务---当前线程%@",[NSThread currentThread]);
        
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"----开始执行第5个任务---当前线程%@",[NSThread currentThread]);
        
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----结束执行第5个任务---当前线程%@",[NSThread currentThread]);
        
        dispatch_semaphore_signal(semaphore);
    });
    
    NSLog(@"----end-----当前线程---%@",[NSThread currentThread]);
}

//Dispatch I/O
-(void)io{
    //以下为苹果中使用Dispatch I/O和Dispatch Data的例子
//    dispatch_queue_t pipe_q = dispatch_queue_create("PipeQ",NULL);
//    dispatch_fd_t fd = 0;
//    dispatch_io_t pipe_channel = dispatch_io_create(DISPATCH_IO_STREAM,fd,pipe_q,^(int err){
//        close(fd);
//    });
//
//    *out_fd = fdpair[i];
//
//    dispatch_io_set_low_water(pipe_channel,SIZE_MAX);
//
//    dispatch_io_read(pipe_channel,0,SIZE_MAX,pipe_q, ^(bool done,dispatch_data_t pipe data,int err){
//        if(err == 0)
//        {
//            size_t len = dispatch_data_get_size(pipe data);
//            if(len > 0)
//            {
//                const char *bytes = NULL;
//                char *encoded;
//
//                dispatch_data_t md = dispatch_data_create_map(pipe data,(const void **)&bytes,&len);
//                asl_set((aslmsg)merged_msg,ASL_KEY_AUX_DATA,encoded);
//                free(encoded);
//                _asl_send_message(NULL,merged_msg,-1,NULL);
//                asl_msg_release(merged_msg);
//                dispatch_release(md);
//            }
//        }
//
//        if(done)
//        {
//            dispatch_semaphore_signal(sem);
//            dispatch_release(pipe_channel);
//            dispatch_release(pipe_q);
//        }
//    });
}

//隔断方法：当前面的写入操作全部完成之后，再执行后面的读取任务。当然也可以用Dispatch Group和dispatch_set_target_queue,只是比较而言，dispatch_barrier_async会更加顺滑
-(void)barrier{
    NSLog(@"----start-----当前线程---%@",[NSThread currentThread]);
    
    dispatch_queue_t queue = dispatch_queue_create("com.test.testQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 第一个写入任务
        [NSThread sleepForTimeInterval:3];
        
        NSLog(@"----执行第一个写入任务---当前线程%@",[NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        // 第二个写入任务
        [NSThread sleepForTimeInterval:1];
        
        NSLog(@"----执行第二个任务---当前线程%@",[NSThread currentThread]);
        
    });
    
    dispatch_barrier_async(queue, ^{
        // 等待处理
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----等待前面的任务完成---当前线程%@",[NSThread currentThread]);
        
    });
    
    dispatch_async(queue, ^{
        // 第一个读取任务
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----执行第一个读取任务---当前线程%@",[NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        // 第二个读取任务
        [NSThread sleepForTimeInterval:2];
        
        NSLog(@"----执行第二个读取任务---当前线程%@",[NSThread currentThread]);
        
    });
    
    NSLog(@"----end-----当前线程---%@",[NSThread currentThread]);
}

//场景：当追加大量处理到Dispatch Queue时，在追加处理的过程中，有时希望不执行已追加的处理。例如演算结果被Block截获时，一些处理会对这个演算结果造成影响。在这种情况下，只要挂起Dispatch Queue即可。当可以执行时再恢复。
//总结:dispatch_suspend，dispatch_resume提供了“挂起、恢复”队列的功能，简单来说，就是可以暂停、恢复队列上的任务。但是这里的“挂起”，并不能保证可以立即停止队列上正在运行的任务，也就是如果挂起之前已经有队列中的任务在进行中，那么该任务依然会被执行完毕
-(void)resumeSuspend{
    NSLog(@"----start-----当前线程---%@",[NSThread currentThread]);
    
    dispatch_queue_t queue = dispatch_queue_create("com.test.testQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        // 执行第一个任务
        [NSThread sleepForTimeInterval:5];
        
        NSLog(@"----执行第一个任务---当前线程%@",[NSThread currentThread]);
        
    });
    
    dispatch_async(queue, ^{
        // 执行第二个任务
        [NSThread sleepForTimeInterval:5];
        
        NSLog(@"----执行第二个任务---当前线程%@",[NSThread currentThread]);
        
    });
    
    dispatch_async(queue, ^{
        // 执行第三个任务
        [NSThread sleepForTimeInterval:5];
        
        NSLog(@"----执行第三个任务---当前线程%@",[NSThread currentThread]);
    });
    
    //此时发现意外情况，挂起队列
    NSLog(@"suspend");
    dispatch_suspend(queue);
    
    //挂起10秒之后，恢复正常
    [NSThread sleepForTimeInterval:10];
    
    //恢复队列
    NSLog(@"resume");
    dispatch_resume(queue);
    
    NSLog(@"----end-----当前线程---%@",[NSThread currentThread]);
}


@end
