#import <Cocoa/Cocoa.h>
#include "clock.h"
@interface ClockView : NSView
@property NSColor *ink;
@property NSTimer *timer;
@property NSInteger lastSecond;
@property NSUInteger hoveredEdges;
@property NSTrackingArea *edgeTracking;
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
 // A short, inset L marks only the corner under the pointer.
 if((self.hoveredEdges&3)&&(self.hoveredEdges&12)){
  double x=(self.hoveredEdges&1)?5:self.bounds.size.width-5;
  double y=(self.hoveredEdges&4)?5:self.bounds.size.height-5;
  double dx=(self.hoveredEdges&1)?12:-12,dy=(self.hoveredEdges&4)?12:-12;
  NSBezierPath *grip=[NSBezierPath bezierPath];[grip moveToPoint:NSMakePoint(x,y+dy)];
  [grip lineToPoint:NSMakePoint(x,y)];[grip lineToPoint:NSMakePoint(x+dx,y)];
  grip.lineWidth=1.25;grip.lineCapStyle=NSLineCapStyleRound;grip.lineJoinStyle=NSLineJoinStyleRound;
  [[NSColor colorWithWhite:.48 alpha:1]setStroke];[grip stroke];
 }
}
// Only hovered corners display a small grip; edge resizing keeps its native cursor.
- (void)updateTrackingAreas {
 [super updateTrackingAreas];if(self.edgeTracking)[self removeTrackingArea:self.edgeTracking];
 self.edgeTracking=[[NSTrackingArea alloc]initWithRect:NSZeroRect options:NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways|NSTrackingInVisibleRect owner:self userInfo:nil];[self addTrackingArea:self.edgeTracking];
 self.window.acceptsMouseMovedEvents=YES;
}
- (void)mouseMoved:(NSEvent *)event {
 NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
 NSUInteger edges=(p.x<20?1:0)|(p.x>self.bounds.size.width-20?2:0)|(p.y<20?4:0)|(p.y>self.bounds.size.height-20?8:0);
 if(edges!=self.hoveredEdges){self.hoveredEdges=edges;self.needsDisplay=YES;}
}
- (void)mouseEntered:(NSEvent *)event {[self mouseMoved:event];}
- (void)mouseExited:(NSEvent *)event {self.hoveredEdges=0;self.needsDisplay=YES;}
- (NSCursor *)diagonalCursor:(BOOL)descending {
 NSImage *image=[[NSImage alloc]initWithSize:NSMakeSize(24,24)];[image lockFocus];
 NSBezierPath *p=[NSBezierPath bezierPath];
 if(descending){[p moveToPoint:NSMakePoint(5,19)];[p lineToPoint:NSMakePoint(19,5)];[p moveToPoint:NSMakePoint(5,13)];[p lineToPoint:NSMakePoint(5,19)];[p lineToPoint:NSMakePoint(11,19)];[p moveToPoint:NSMakePoint(13,5)];[p lineToPoint:NSMakePoint(19,5)];[p lineToPoint:NSMakePoint(19,11)];}
 else {[p moveToPoint:NSMakePoint(5,5)];[p lineToPoint:NSMakePoint(19,19)];[p moveToPoint:NSMakePoint(5,11)];[p lineToPoint:NSMakePoint(5,5)];[p lineToPoint:NSMakePoint(11,5)];[p moveToPoint:NSMakePoint(13,19)];[p lineToPoint:NSMakePoint(19,19)];[p lineToPoint:NSMakePoint(19,13)];}
 p.lineJoinStyle=NSLineJoinStyleRound;p.lineCapStyle=NSLineCapStyleRound;
 [NSColor.blackColor setStroke];p.lineWidth=3.5;[p stroke];[NSColor.whiteColor setStroke];p.lineWidth=1.5;[p stroke];[image unlockFocus];
 return [[NSCursor alloc]initWithImage:image hotSpot:NSMakePoint(12,12)];
}
- (void)resetCursorRects {
 [super resetCursorRects];double w=self.bounds.size.width,h=self.bounds.size.height;
 [self addCursorRect:NSMakeRect(0,10,10,h-20) cursor:NSCursor.resizeLeftRightCursor];[self addCursorRect:NSMakeRect(w-10,10,10,h-20) cursor:NSCursor.resizeLeftRightCursor];
 [self addCursorRect:NSMakeRect(10,0,w-20,10) cursor:NSCursor.resizeUpDownCursor];[self addCursorRect:NSMakeRect(10,h-10,w-20,10) cursor:NSCursor.resizeUpDownCursor];
 NSCursor *down=[self diagonalCursor:YES],*up=[self diagonalCursor:NO];
 [self addCursorRect:NSMakeRect(0,0,20,20) cursor:down];[self addCursorRect:NSMakeRect(w-20,h-20,20,20) cursor:down];
 [self addCursorRect:NSMakeRect(w-20,0,20,20) cursor:up];[self addCursorRect:NSMakeRect(0,h-20,20,20) cursor:up];
}
- (void)setFrameSize:(NSSize)size {[super setFrameSize:size];[self.window invalidateCursorRectsForView:self];self.needsDisplay=YES;}
- (void)mouseDown:(NSEvent *)event {
 if(event.modifierFlags & NSEventModifierFlagControl) {[self rightMouseDown:event];return;}
 NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
 NSRect original=self.window.frame; NSPoint start=NSEvent.mouseLocation;
 BOOL corner=(p.x<20||p.x>self.bounds.size.width-20)&&(p.y<20||p.y>self.bounds.size.height-20);
 double zone=corner?20:10;
 BOOL left=p.x<zone,right=p.x>self.bounds.size.width-zone,top=p.y<zone,bottom=p.y>self.bounds.size.height-zone;
 if(!(left||right||top||bottom)) {[self.window performWindowDragWithEvent:event];return;}
 for(;;) {
  NSEvent *next=[self.window nextEventMatchingMask:NSEventMaskLeftMouseDragged|NSEventMaskLeftMouseUp];
  if(next.type==NSEventTypeLeftMouseUp)break;
  NSPoint now=NSEvent.mouseLocation;double dx=now.x-start.x,dy=now.y-start.y;
  double w=original.size.width;
  if(left||right)w+=(left?-dx:dx);else w+=(bottom?-dy:dy)*clockface::ratio;
  w=MAX(240,w); double h=w/clockface::ratio;
  NSRect frame=NSMakeRect(left?NSMaxX(original)-w:original.origin.x,top?original.origin.y:NSMaxY(original)-h,w,h);
  [self.window setFrame:frame display:YES];
 }
}
- (void)rightMouseDown:(NSEvent *)event {
 NSMenu *m=[NSMenu new];
 for(NSArray *entry in @[@[@"Text Color…",@"chooseColor:"],@[@"Reset Color",@"resetColor:"],@[@"Quit BK Big Clock",@"quit:"]]) {
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
 self.window=[[ClockWindow alloc]initWithContentRect:NSMakeRect(0,0,608,200) styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
 self.window.title=@"BK Big Clock"; self.window.backgroundColor=NSColor.blackColor; self.window.opaque=YES;self.window.hasShadow=NO;
 self.window.contentAspectRatio=NSMakeSize(clockface::width,clockface::height);self.window.contentMinSize=NSMakeSize(240,240/clockface::ratio);self.window.delegate=self;
 self.window.contentView=[[ClockView alloc]initWithFrame:NSMakeRect(0,0,608,200)];
 [self.window center];[self.window setFrameAutosaveName:@"ClockWindow"];
 NSRect frame=self.window.frame;frame.size.width=frame.size.height*clockface::ratio;[self.window setFrame:frame display:YES];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {return YES;}
@end
int main(){@autoreleasepool{
 NSApplication *app=NSApplication.sharedApplication;[app setActivationPolicy:NSApplicationActivationPolicyRegular];
 NSMenu *menu=[NSMenu new];NSMenuItem *root=[NSMenuItem new];[menu addItem:root];NSMenu *sub=[NSMenu new];[sub addItemWithTitle:@"Quit BK Big Clock" action:@selector(terminate:) keyEquivalent:@"q"];root.submenu=sub;app.mainMenu=menu;
 AppDelegate *delegate=[AppDelegate new];app.delegate=delegate;[app run];
}}
