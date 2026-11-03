#pragma once
#include <array>
#include <ctime>
#include <cmath>
namespace clockface {
constexpr double width=760, height=250, ratio=width/height;
struct Point { double x,y; };
using Polygon=std::array<Point,6>;
constexpr unsigned masks[]={0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f};
// Clockwise segment order: top, upper right, lower right, bottom,
// lower left, upper left, middle. Coordinates use a top-left origin.
constexpr Polygon segments[]={
 {{{14,0},{82,0},{89,7},{80,16},{16,16},{7,7}}},
 {{{91,10},{96,16},{96,78},{88,86},{79,77},{79,23}}},
 {{{88,94},{96,102},{96,164},{91,170},{79,157},{79,103}}},
 {{{16,164},{80,164},{89,173},{82,180},{14,180},{7,173}}},
 {{{8,94},{17,103},{17,157},{5,170},{0,164},{0,102}}},
 {{{5,10},{17,23},{17,77},{8,86},{0,78},{0,16}}},
 {{{16,82},{80,82},{88,90},{80,98},{16,98},{8,90}}}
};
// Small corner radii soften the face without blurring the clock at small sizes.
inline Point inset(Point vertex,Point toward) {
 double dx=toward.x-vertex.x,dy=toward.y-vertex.y,len=std::hypot(dx,dy);
 double amount=len>0?std::fmin(1.1,len/3)/len:0;
 return {vertex.x+dx*amount,vertex.y+dy*amount};
}
inline std::array<int,6> digits(std::time_t now) {
 std::tm t{};
#ifdef _WIN32
 localtime_s(&t,&now);
#else
 localtime_r(&now,&t);
#endif
 return {t.tm_hour/10,t.tm_hour%10,t.tm_min/10,t.tm_min%10,t.tm_sec/10,t.tm_sec%10};
}
template<class Draw> void render(std::time_t now,Draw draw) {
 auto d=digits(now);
 constexpr double positions[]={24,128,280,384,536,640};
 for(int i=0;i<6;++i) for(int s=0;s<7;++s) {
  auto p=segments[s]; for(auto &v:p) {v.x+=positions[i];v.y+=35;}
  draw(p,(masks[d[i]]&(1u<<s))!=0);
 }
 for(double x:{244.,500.}) for(double y:{76.,150.}) {
  Polygon p={{{x,y},{x+16,y},{x+16,y+16},{x,y+16},{x,y+16},{x,y}}};draw(p,true);
 }
}
}
