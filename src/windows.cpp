#define UNICODE
#define _UNICODE
#define NOMINMAX
#include <windows.h>
#include <windowsx.h>
#include <commdlg.h>
#include <gdiplus.h>
#include <algorithm>
#include "clock.h"
using namespace Gdiplus;
static COLORREF ink=RGB(173,173,173),custom[16]{};
static HWND clockWindow;
static const wchar_t *settings=L"Software\\BK Clock";
static void saveColor(){HKEY key;if(RegCreateKeyExW(HKEY_CURRENT_USER,settings,0,nullptr,0,KEY_WRITE,nullptr,&key,nullptr)==ERROR_SUCCESS){DWORD c=ink;RegSetValueExW(key,L"Color",0,REG_DWORD,(BYTE*)&c,sizeof c);RegCloseKey(key);}}
static void armTimer(HWND w){SYSTEMTIME t;GetLocalTime(&t);SetTimer(w,1,1005-t.wMilliseconds,nullptr);}
static void paint(HWND w){
 PAINTSTRUCT ps;HDC dc=BeginPaint(w,&ps);RECT rc;GetClientRect(w,&rc);
 if(rc.right>0&&rc.bottom>0){
  Bitmap buffer(rc.right,rc.bottom,PixelFormat32bppPARGB);Graphics g(&buffer);g.Clear(Color(255,0,0,0));g.SetSmoothingMode(SmoothingModeAntiAlias);
  g.ScaleTransform((REAL)(rc.right/clockface::width),(REAL)(rc.bottom/clockface::height));
  SolidBrush active(Color(255,GetRValue(ink),GetGValue(ink),GetBValue(ink))),inactive(Color(255,6,6,6));
  clockface::render(time(nullptr),[&](const clockface::Polygon &p,bool on){GraphicsPath path;auto last=clockface::inset(p[0],p[5]);
   for(int i=0;i<6;++i){auto before=clockface::inset(p[i],p[(i+5)%6]);auto after=clockface::inset(p[i],p[(i+1)%6]);path.AddLine((REAL)last.x,(REAL)last.y,(REAL)before.x,(REAL)before.y);path.AddBezier((REAL)before.x,(REAL)before.y,(REAL)p[i].x,(REAL)p[i].y,(REAL)p[i].x,(REAL)p[i].y,(REAL)after.x,(REAL)after.y);last=after;}path.CloseFigure();g.FillPath(on?&active:&inactive,&path);});
  Graphics screen(dc);screen.DrawImage(&buffer,0,0);
 }EndPaint(w,&ps);
}
static LRESULT CALLBACK proc(HWND w,UINT msg,WPARAM wp,LPARAM lp){switch(msg){
 case WM_CREATE:armTimer(w);return 0;
 case WM_TIMER:KillTimer(w,1);InvalidateRect(w,nullptr,FALSE);armTimer(w);return 0;
 case WM_TIMECHANGE:InvalidateRect(w,nullptr,FALSE);armTimer(w);return 0;
 case WM_PAINT:paint(w);return 0;
 case WM_ERASEBKGND:return 1;
 case WM_NCCALCSIZE:return 0;
 case WM_NCHITTEST:{POINT p={GET_X_LPARAM(lp),GET_Y_LPARAM(lp)};RECT r;GetWindowRect(w,&r);int edge=std::max(6,GetSystemMetrics(SM_CXSIZEFRAME));bool l=p.x<r.left+edge,rr=p.x>=r.right-edge,t=p.y<r.top+edge,b=p.y>=r.bottom-edge;return t?(l?HTTOPLEFT:rr?HTTOPRIGHT:HTTOP):b?(l?HTBOTTOMLEFT:rr?HTBOTTOMRIGHT:HTBOTTOM):l?HTLEFT:rr?HTRIGHT:HTCAPTION;}
 case WM_GETMINMAXINFO:{auto m=(MINMAXINFO*)lp;m->ptMinTrackSize={280,70};return 0;}
 case WM_SIZING:{RECT *r=(RECT*)lp;int width=std::max(280L,r->right-r->left);if(wp==WMSZ_TOP||wp==WMSZ_BOTTOM)width=std::max(280L,(r->bottom-r->top)*4);int height=width/4;
  if(wp==WMSZ_LEFT||wp==WMSZ_TOPLEFT||wp==WMSZ_BOTTOMLEFT)r->left=r->right-width;else r->right=r->left+width;
  if(wp==WMSZ_TOP||wp==WMSZ_TOPLEFT||wp==WMSZ_TOPRIGHT)r->top=r->bottom-height;else r->bottom=r->top+height;return TRUE;}
 case WM_NCRBUTTONUP:case WM_CONTEXTMENU:{POINT p;GetCursorPos(&p);HMENU menu=CreatePopupMenu();AppendMenuW(menu,MF_STRING,1,L"Text Color…");AppendMenuW(menu,MF_STRING,2,L"Reset Color");AppendMenuW(menu,MF_SEPARATOR,0,nullptr);AppendMenuW(menu,MF_STRING,3,L"Quit BK Clock");SetForegroundWindow(w);int action=TrackPopupMenu(menu,TPM_RETURNCMD|TPM_RIGHTBUTTON,p.x,p.y,0,w,nullptr);DestroyMenu(menu);
  if(action==1){CHOOSECOLORW c={};c.lStructSize=sizeof c;c.hwndOwner=w;c.rgbResult=ink;c.lpCustColors=custom;c.Flags=CC_FULLOPEN|CC_RGBINIT;if(ChooseColorW(&c)){ink=c.rgbResult;saveColor();InvalidateRect(w,nullptr,FALSE);}}
  if(action==2){ink=RGB(173,173,173);saveColor();InvalidateRect(w,nullptr,FALSE);}if(action==3)DestroyWindow(w);return 0;}
 case WM_NCLBUTTONDBLCLK:return 0;
 case WM_DPICHANGED:{RECT *r=(RECT*)lp;int width=r->right-r->left;SetWindowPos(w,nullptr,r->left,r->top,width,width/4,SWP_NOZORDER|SWP_NOACTIVATE);return 0;}
 case WM_DESTROY:KillTimer(w,1);PostQuitMessage(0);return 0;
 }return DefWindowProcW(w,msg,wp,lp);}
int WINAPI wWinMain(HINSTANCE instance,HINSTANCE,LPWSTR,int){
 SetProcessDPIAware();ULONG_PTR token;GdiplusStartupInput startup;if(GdiplusStartup(&token,&startup,nullptr)!=Ok)return 1;
 DWORD size=sizeof ink,type=0;COLORREF saved;if(RegGetValueW(HKEY_CURRENT_USER,settings,L"Color",RRF_RT_REG_DWORD,&type,&saved,&size)==ERROR_SUCCESS)ink=saved&0xffffff;
 WNDCLASSW wc={};wc.lpfnWndProc=proc;wc.hInstance=instance;wc.lpszClassName=L"BKClock";wc.hCursor=LoadCursor(nullptr,IDC_ARROW);wc.hIcon=LoadIcon(nullptr,IDI_APPLICATION);RegisterClassW(&wc);
 clockWindow=CreateWindowExW(WS_EX_APPWINDOW,L"BKClock",L"BK Clock",WS_POPUP|WS_THICKFRAME|WS_SYSMENU,(GetSystemMetrics(SM_CXSCREEN)-800)/2,(GetSystemMetrics(SM_CYSCREEN)-200)/2,800,200,nullptr,nullptr,instance,nullptr);
 if(!clockWindow){GdiplusShutdown(token);return 1;}ShowWindow(clockWindow,SW_SHOW);MSG msg;while(GetMessageW(&msg,nullptr,0,0)>0){TranslateMessage(&msg);DispatchMessageW(&msg);}GdiplusShutdown(token);return 0;
}
