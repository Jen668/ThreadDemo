# 线程编程指南 -- 关于线程编程

多年来，计算机的最高性能在很大程度上受限于计算机内核中单个微处理器的运算速度。然而，随着单个处理器的运算速度开始达到其实际限制，芯片制造商切换到多核设计来使计算机有机会同时执行多个任务。虽然OS X无论何时都在利用这些内核执行与系统相关的任务，但我们自己的应用程序也可以通过线程来利用这些内核。


## 什么是线程？

线程是在应用程序内部实现多个执行路径的相对轻量级的方式。在系统层面，程序并排运行，系统根据程序的需求和其他程序的需求为每个程序分配执行时间。但是在每个程序中，存在一个或多个可用于同时或以几乎同时的方式执行不同的任务的执行线程。系统本身实际上管理着这些执行线程，并调度它们到可用内核上运行。同时，还能根据需要提前中断它们以允许其他线程运行。

从技术角度讲，线程是管理代码执行所需的内核级和应用级数据结构的组合。内核级数据结构协调调度事件到线程和在一个可用内核中抢先调度线程。应用级数据结构包含用于存储函数调用的调用堆栈和应用程序需要用于管理和操作线程的属性和状态的结构。

在非并发的应用程序中，只有一个执行线程。该线程以应用程序的主例程开始和结束，并逐个分支到不同的方法或函数中，以实现应用程序的整体行为。相比之下，支持并发的应用程序从一个线程开始，并根据需要添加更多线程来创建额外的执行路径。每个新路径都有自己的独立于应用程序主例程中的代码运行的自定义启动例程。在应用程序中有多个线程提供了两个非常重要的潜在优势：
- 多个线程可以提高应用程序的感知响应能力。
- 多个线程可以提高应用程序在多核系统上的实时性能。

如果应用程序只有一个线程，那么该线程必须做所有的事情。其必须响应事件，更新应用程序的窗口，并执行实现应用程序行为所需的所有计算。只有一个线程的问题是它一次只能做一件事情。如果一个计算需要很长时间才能完成，那么当我们的代码忙于计算它所需的值时，应用程序会停止响应用户事件和更新其窗口。如果这种行为持续时间足够长，用户可能会认为我们的应用程序被挂起了并试图强行退出它。但是，如果将自定义计算移至单独的线程，则应用程序的主线程可以更及时地自由响应用户交互。

随着多核计算机的普及，线程提供了一种提高某些类型应用程序性能的方法。执行不同任务的线程可以在不同的处理器内核上同时执行，从而使应用程序可以在给定的时间内执行更多的工作。

当然，线程并不是解决应用程序性能问题的万能药物。线程提供的益处也会带来潜在的问题。在应用程序中执行多个路径可能会增加代码的复杂度。每个线程必须与其他线程协调行动，以防止它破坏应用程序的状态信息。由于单个应用程序中的线程共享相同的内存空间，所有它们可以访问所有相同的数据结构。如果两个线程试图同时操作相同的数据结构，则其中一个线程可能会以破坏数据结构的方式覆盖另一个线程的更改。即使有适当的保护措施，我们仍然需要对编译器优化保持注意，因为编译器优化会在我们的代码中引入细微的错误。

## 线程术语

在讨论线程及其支持技术之前，有必要定义一些基本术语。

如果你熟悉UNIX系统，则可能会发现本文档中的术语“任务”的使用有所不同。在UNIX系统中，有时使用术语“任务”来指代正在运行的进程。

本文档采用一下术语：
- 术语“线程”用于指代单独的代码执行路径。
- 术语“进程”用于指代正在运行的可执行文件，它可以包含多个线程。
- 术语“任务”用于指代需要执行的抽象工作概念。

## 线程的替代方案

自己创建线程的一个问题是它们会给代码添加不确定性。线程是一种相对较底层且复杂的支持应用程序并发的方式。如果不完全了解设计的含义，则可能会遇到同步或校时问题，其严重程度可能会从细微的行为变化到应用程序崩溃以及用户数据的损坏。

另一个要考虑的因素是是否需要线程或并发。线程解决了如何在同一进程中同时执行多个代码路径的具体问题。但是在有些情况下，并不能保证并发执行我们需要的工作。线程会在内存消耗和CPU时间方面为进程带来了巨大的开销。我们可能会发现这种开销对于预期的任务来说太大了，或者其他选项更容易实现。

下表列出了线程的一些替代方案。
| Technology | Description |
|---------------|--------------|
| Operation objects | 在OS X v10.5中引入的操作对象是通常在辅助线程上执行的任务的封装器。这个封装器隐藏了执行任务的线程管理方面，让我们可以自由地专注于任务本身。通常将操作对象与一个操作队列对象结合使用，操作队列对象实际上管理一个或多个线程上的操作对象的执行。 |
| Grand Central Dispatch (GCD) | 在OS X v10.6中引入的Grand Central Dispatch是线程的另一种替代方案，可以让我们专注于需要执行的任务而不是线程管理。使用GCD，我们可以定义要执行的任务并将其添加到工作队列中，该工作队列可以在适当的线程上处理我们的任务计划。工作队列会考虑可用内核的数量和当前负载，以便比使用线程更有效地执行任务。 |
| Idle-time notifications | 对于相对较短且优先级很低的任务，空闲时间通知让我们可以在应用程序不太忙时执行任务。Cocoa使用`NSNotificationQueue`对象为空闲时间通知提供支持。要请求空闲时间通知，请使用`NSPostWhenIdle`选项向默认`NSNotificationQueue`对象发布通知。队列会延迟通知对象的传递，直到run loop变为空闲状态。 |
| Asynchronous functions | 系统接口包含许多为我们提供自动并发性的异步功能。这些API可以使用系统守护进程和进程或者创建自定义线程来执行任务并将结果返回给我们。在设计应用程序时，寻找提供异步行为的函数，并考虑使用它们而不是在自定义线程上使用等效的同步函数。 |
| Timers | 可以在应用程序的主线程上使用定时器来执行相对于使用线程而言过于微不足道的定期任务，但是需要定期维护。 |
| Separate processes | 尽管比线程更加重量级，但在任务仅与应用程序切向相关的情况下，创建单独的进程可能很有用。如果任务需要大量内存或必须使用root权限执行，则可以使用进程。例如，我们可以使用64位服务器进程来计算大型数据集，而我们的32位应用程序会将结果显示给用户。 |

> **注意**：使用`fork`函数启动单独的进程时，必须使用与调用`exec`函数或类似函数相同的方式调用`fork`函数。依赖于Core Foundation，Cocoa或者Core Data框架（显式或隐式）的应用程序必须对`exec`函数进行后续调用，否则这些框架的行为可能会不正确。

## 线程支持

OS X和iOS系统提供了多种技术来在我们的应用程序中创建线程，并且还为管理和同步需要在这些线程上完成的工作提供支持。以下各节介绍了在OS X和iOS中使用线程时需要注意的一些关键技术。

### 线程组件

尽管线程的底层实现机制是Mach线程，但很少（如果有的话）在Mach层面上使用线程。相反，我们通常使用更方便的POSIX API或其衍生工具之一。Mach实现确实提供了所有线程的基本特征，包括抢先执行模型和调度线程使它们彼此独立的能力。

下表列出了可以在应用程序中使用的线程技术。

| Technology | Description |
|--------------|---------------|
| Cocoa threads | Cocoa使用`NSThread`类实现线程。Cocoa也在`NSObject`类中提供了方法来生成新线程并在已经运行的线程上执行代码。 |
| POSIX threads | POSIX线程提供了基于C语言的接口来创建线程。如果我们不是在编写一个Cocoa应用程序，则这是创建线程的最佳选择。POSIX接口使用起来相对简单，并为配置线程提供了足够的灵活性。 |
| Multiprocessing<br>Services | Multiprocessing Services（多进程服务）是传统的基于C语言的接口，其被从旧版本Mac OS系统中过渡来的应用程序所使用。这项技术仅适用于OS X，应该避免在任何新的开发中使用它。相反，应该使用`NSThread`类或者POSIX线程。 |

启动线程后，线程将以三种主要状态中的一种来运行：运行中，准备就绪或者阻塞。如果一个线程当前没有运行，那么它可能处于阻塞状态并等待输入，或者它已准备好运行，但尚未安排执行。线程持续在这些状态之间来回切换，直到它最终退出并切换到终止状态。


