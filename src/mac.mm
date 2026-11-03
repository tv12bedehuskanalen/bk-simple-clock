#import <Cocoa/Cocoa.h>
#include "clock.h"
@interface ClockView : NSView
@property NSColor *ink;
@property NSTimer *timer;
@property NSInteger lastSecond;
- (void)tick;
@end
@implementation ClockView
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (instancetype)initWithFrame:(NSRect)frame {
 if((self=[super initWithFrame:frame])) {
  NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
  if([d objectForKey:@"red"]) self.ink=[NSColor colorWithSRGBRed:[d doubleForKey:@"red"] green:[d doubleForKey:@"green"] blue:[d doubleForKey:@"blue"] alpha:1];
  else self.ink=[NSColor colorWithSRGBRed:.68 green:.68 blue:.68 alpha:1];
  self.lastSecond=-1;
  [self tick];
 } return self;
}
- (void)tick {
 NSInteger sec=(NSInteger)NSDate.date.timeIntervalSince1970;
 if(sec!=self.lastSecond) {self.lastSecond=sec;self.needsDisplay=YES;}
 // Re-align each tick to wall time: no accumulated drift, including after sleep.
 double delay=1.005-fmod(NSDate.date.timeIntervalSince1970,1.0);
 __weak ClockView *weakSelf=self;
 self.timer=[NSTimer timerWithTimeInterval:delay repeats:NO block:^(NSTimer *t){[weakSelf tick];}];
 [NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)drawRect:(NSRect)dirty {
 [NSColor.blackColor setFill]; NSRectFill(self.bounds);
 [NSGraphicsContext saveGraphicsState];
 NSAffineTransform *tr=[NSAffineTransform transform];
 [tr scaleXBy:self.bounds.size.width/clockface::width yBy:self.bounds.size.height/clockface::height];[tr concat];
 clockface::render(time(nullptr),[&](const clockface::Polygon &p,bool on){
  [(on?self.ink:[NSColor colorWithWhite:.025 alpha:1]) setFill];
  NSBezierPath *path=[NSBezierPath bezierPath];
  auto start=clockface::inset(p[0],p[5]);[path moveToPoint:NSMakePoint(start.x,start.y)];
  for(int i=0;i<6;++i){auto before=clockface::inset(p[i],p[(i+5)%6]);auto after=clockface::inset(p[i],p[(i+1)%6]);
   [path lineToPoint:NSMakePoint(before.x,before.y)];[path curveToPoint:NSMakePoint(after.x,after.y) controlPoint1:NSMakePoint(p[i].x,p[i].y) controlPoint2:NSMakePoint(p[i].x,p[i].y)];
  }[path closePath];[path fill];
 });
 [NSGraphicsContext restoreGraphicsState];
}
- (void)mouseDown:(NSEvent *)event {
 if(event.modifierFlags & NSEventModifierFlagControl) {[self rightMouseDown:event];return;}
 NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
 NSRect original=self.window.frame; NSPoint start=NSEvent.mouseLocation;
 BOOL left=p.x<10,right=p.x>self.bounds.size.width-10,top=p.y<10,bottom=p.y>self.bounds.size.height-10;
 if(!(left||right||top||bottom)) {[self.window performWindowDragWithEvent:event];return;}
 for(;;) {
  NSEvent *next=[self.window nextEventMatchingMask:NSEventMaskLeftMouseDragged|NSEventMaskLeftMouseUp];
  if(next.type==NSEventTypeLeftMouseUp)break;
  NSPoint now=NSEvent.mouseLocation;double dx=now.x-start.x,dy=now.y-start.y;
  double w=original.size.width;
  if(left||right)w+=(left?-dx:dx);else w+=(bottom?-dy:dy)*clockface::ratio;
  w=MAX(280,w); double h=w/clockface::ratio;
  NSRect frame=NSMakeRect(left?NSMaxX(original)-w:original.origin.x,top?original.origin.y:NSMaxY(original)-h,w,h);
  [self.window setFrame:frame display:YES];
 }
}
- (void)rightMouseDown:(NSEvent *)event {
 NSMenu *m=[NSMenu new];
 for(NSArray *entry in @[@[@"Text Color…",@"chooseColor:"],@[@"Reset Color",@"resetColor:"],@[@"Quit BK Clock",@"quit:"]]) {
  NSMenuItem *i=[[NSMenuItem alloc]initWithTitle:entry[0] action:NSSelectorFromString(entry[1]) keyEquivalent:@""];i.target=self;[m addItem:i];
 }
 [NSMenu popUpContextMenu:m withEvent:event forView:self];
}
- (void)chooseColor:(id)sender {NSColorPanel *p=NSColorPanel.sharedColorPanel;p.showsAlpha=NO;p.color=self.ink;p.target=self;p.action=@selector(colorChanged:);[p orderFront:nil];}
- (void)saveColor {NSColor *c=[self.ink colorUsingColorSpace:NSColorSpace.sRGBColorSpace];NSUserDefaults *d=NSUserDefaults.standardUserDefaults;[d setDouble:c.redComponent forKey:@"red"];[d setDouble:c.greenComponent forKey:@"green"];[d setDouble:c.blueComponent forKey:@"blue"];self.needsDisplay=YES;}
- (void)colorChanged:(NSColorPanel *)sender {self.ink=sender.color;[self saveColor];}
- (void)resetColor:(id)sender {self.ink=[NSColor colorWithSRGBRed:.68 green:.68 blue:.68 alpha:1];[self saveColor];}
- (void)quit:(id)sender {[NSApp terminate:nil];}
@end
@interface ClockWindow : NSWindow
@end
@implementation ClockWindow
- (BOOL)canBecomeKeyWindow {return YES;}
- (BOOL)canBecomeMainWindow {return YES;}
@end
@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>
@property NSWindow *window;
@end
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)n {
 self.window=[[ClockWindow alloc]initWithContentRect:NSMakeRect(0,0,800,200) styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
 self.window.title=@"BK Clock"; self.window.backgroundColor=NSColor.blackColor; self.window.opaque=YES;self.window.hasShadow=NO;
 self.window.contentAspectRatio=NSMakeSize(4,1);self.window.contentMinSize=NSMakeSize(280,70);self.window.delegate=self;
 self.window.contentView=[[ClockView alloc]initWithFrame:NSMakeRect(0,0,800,200)];
 [self.window center];[self.window setFrameAutosaveName:@"ClockWindow"];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {return YES;}
@end
int main(){@autoreleasepool{
 NSApplication *app=NSApplication.sharedApplication;[app setActivationPolicy:NSApplicationActivationPolicyRegular];
 NSMenu *menu=[NSMenu new];NSMenuItem *root=[NSMenuItem new];[menu addItem:root];NSMenu *sub=[NSMenu new];[sub addItemWithTitle:@"Quit BK Clock" action:@selector(terminate:) keyEquivalent:@"q"];root.submenu=sub;app.mainMenu=menu;
 AppDelegate *delegate=[AppDelegate new];app.delegate=delegate;[app run];
}}
