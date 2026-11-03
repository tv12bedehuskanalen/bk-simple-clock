#include "../src/clock.h"
#include <cassert>
#include <cstdlib>
#include <iostream>
// The original corner artifacts came from segment overlap. Check every pair
// with the separating-axis test so future geometry changes cannot reintroduce it.
bool separated(const clockface::Polygon &a,const clockface::Polygon &b){
 for(auto &poly:{a,b}) {
  for(int i=0;i<6;++i){
  auto p=poly[i],q=poly[(i+1)%6];double nx=q.y-p.y,ny=p.x-q.x;if(nx==0&&ny==0)continue;
  double amin=1e9,amax=-1e9,bmin=1e9,bmax=-1e9;
  for(auto v:a){double d=v.x*nx+v.y*ny;amin=std::fmin(amin,d);amax=std::fmax(amax,d);}
  for(auto v:b){double d=v.x*nx+v.y*ny;bmin=std::fmin(bmin,d);bmax=std::fmax(bmax,d);}
  if(amax<=bmin||bmax<=amin)return true;
  }
 }
 return false;
}
int main(){
 setenv("TZ","UTC",1);tzset();
 assert((clockface::digits(0)==std::array<int,6>{0,0,0,0,0,0}));
 assert((clockface::digits(86399)==std::array<int,6>{2,3,5,9,5,9}));
 assert((clockface::digits(86400)==std::array<int,6>{0,0,0,0,0,0}));
 for(int i=0;i<7;++i)for(int j=i+1;j<7;++j)assert(separated(clockface::segments[i],clockface::segments[j]));
 int count=0;clockface::render(0,[&](const clockface::Polygon &p,bool){++count;for(auto v:p){assert(v.x>=0&&v.x<=clockface::width&&v.y>=0&&v.y<=clockface::height);}});assert(count==46);
 std::cout<<"Clock rollover, drawing bounds, and non-overlapping segments passed.\n";
}
