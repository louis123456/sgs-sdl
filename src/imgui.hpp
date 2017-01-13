

#pragma once
#include <sgs_cppbc.h>
#include "../ext/src/imgui/imgui.h"

template<> inline void sgs_PushVar<ImVec2>( SGS_CTX, const ImVec2& v )
{
	sgs_PushReal( C, v.x );
	sgs_PushReal( C, v.y );
}
template<> struct sgs_GetVar<ImVec2>
{
	ImVec2 operator () ( SGS_CTX, sgs_StkIdx item )
	{
		sgs_Real x, y;
		if( sgs_ParseReal( C, item, &x ) && sgs_ParseReal( C, item + 1, &y ) )
			return ImVec2( x, y );
		return ImVec2(0,0);
	}
};
template<> inline void sgs_PushVar<ImVec4>( SGS_CTX, const ImVec4& v )
{
	sgs_PushReal( C, v.x );
	sgs_PushReal( C, v.y );
	sgs_PushReal( C, v.z );
	sgs_PushReal( C, v.w );
}
template<> struct sgs_GetVar<ImVec4>
{
	ImVec4 operator () ( SGS_CTX, sgs_StkIdx item )
	{
		sgs_Real x, y, z, w;
		if( sgs_ParseReal( C, item, &x ) &&
			sgs_ParseReal( C, item + 1, &y ) &&
			sgs_ParseReal( C, item + 2, &z ) &&
			sgs_ParseReal( C, item + 3, &w ) )
			return ImVec4( x, y, z, w );
		return ImVec4(1,1,1,1);
	}
};
// TODO integrate
template<> struct sgs_GetVar<const char*> { const char* operator () ( SGS_CTX, sgs_StkIdx item ){
	char* str = NULL; sgs_ParseString( C, item, &str, NULL ); return str; }};

