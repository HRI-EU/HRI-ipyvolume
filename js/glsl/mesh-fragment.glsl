#ifdef LAMBERT_SHADING
    #define LAMBERT
    uniform vec3 diffuse;
    uniform vec3 emissive;
    uniform float emissiveIntensity;
    uniform float opacity;

    varying vec3 vLightFront;

    #ifdef DOUBLE_SIDED
    	varying vec3 vLightBack;
    #endif

    #include <common>
    #include <packing>
    #include <dithering_pars_fragment>
    #include <color_pars_fragment>
    #include <uv_pars_fragment>
    #include <uv2_pars_fragment>
    #include <map_pars_fragment>
    #include <alphamap_pars_fragment>
    #include <aomap_pars_fragment>
    #include <lightmap_pars_fragment>
    #include <emissivemap_pars_fragment>
    #include <envmap_pars_fragment>
    #include <bsdfs>
    #include <lights_pars_begin>
    #include <fog_pars_fragment>
    #include <shadowmap_pars_fragment>
    #include <shadowmask_pars_fragment>
    #include <specularmap_pars_fragment>
    #include <logdepthbuf_pars_fragment>
    #include <clipping_planes_pars_fragment>
#endif //LAMBERT_SHADING

#ifdef PHONG_SHADING
    #define PHONG

    uniform vec3 diffuse;
    uniform vec3 emissive;
    uniform vec3 specular;

    uniform float shininess;
    uniform float opacity;
    uniform float emissiveIntensity;

    #include <common>
    #include <packing>
    #include <dithering_pars_fragment>
    #include <color_pars_fragment>
    #include <uv_pars_fragment>
    #include <uv2_pars_fragment>
    #include <map_pars_fragment>
    #include <alphamap_pars_fragment>
    #include <aomap_pars_fragment>
    #include <lightmap_pars_fragment>
    #include <emissivemap_pars_fragment>
    #include <envmap_pars_fragment>
    #include <gradientmap_pars_fragment>
    #include <fog_pars_fragment>
    #include <bsdfs>
    #include <lights_pars_begin>
    #include <lights_phong_pars_fragment>
    #include <shadowmap_pars_fragment>
    #include <bumpmap_pars_fragment>
    #include <normalmap_pars_fragment>
    #include <specularmap_pars_fragment>
    #include <logdepthbuf_pars_fragment>
    #include <clipping_planes_pars_fragment>
#endif //PHONG_SHADING

#ifdef PHYSICAL_SHADING
    #define PHYSICAL
    uniform vec3 diffuse;
    uniform vec3 emissive;
    uniform float roughness;
    uniform float metalness;
    uniform float opacity;
    uniform float emissiveIntensity;

    #ifndef STANDARD
    	uniform float clearCoat;
    	uniform float clearCoatRoughness;
    #endif

    varying vec3 vViewPosition;

    #ifndef FLAT_SHADED
    	varying vec3 vNormal;
    #endif

    #include <common>
    #include <packing>
    #include <dithering_pars_fragment>
    #include <color_pars_fragment>
    #include <uv_pars_fragment>
    #include <uv2_pars_fragment>
    #include <map_pars_fragment>
    #include <alphamap_pars_fragment>
    #include <aomap_pars_fragment>
    #include <lightmap_pars_fragment>
    #include <emissivemap_pars_fragment>
    #include <bsdfs>
    #include <cube_uv_reflection_fragment>
    #include <envmap_pars_fragment>
    #include <envmap_physical_pars_fragment>
    #include <fog_pars_fragment>
    #include <lights_pars_begin>
    #include <lights_physical_pars_fragment>
    #include <shadowmap_pars_fragment>
    #include <bumpmap_pars_fragment>
    #include <normalmap_pars_fragment>
    #include <roughnessmap_pars_fragment>
    #include <metalnessmap_pars_fragment>
    #include <logdepthbuf_pars_fragment>
    #include <clipping_planes_pars_fragment>
#endif //PHYSICAL_SHADING

varying vec4 vertex_color;
varying vec3 vertex_position;
varying vec2 vertex_uv;

#ifdef USE_TEXTURE
    uniform sampler2D texture;
    uniform sampler2D texture_previous;
    uniform float animation_time_texture;
#endif


void main(void) 
{
#ifdef DEFAULT_SHADING
    #ifdef USE_RGB
        gl_FragColor = vec4(vertex_color.rgb, 1.0);
    #else
    #ifdef AS_LINE
        gl_FragColor = vec4(vertex_color.rgb, vertex_color.a);
    #else
        vec3 fdx = dFdx( vertex_position );
        vec3 fdy = dFdy( vertex_position );
        vec3 normal = normalize( cross( fdx, fdy ) );
        float diffuse = dot( normal, vec3( 0.0, 0.0, 1.0 ) );

    #ifdef USE_TEXTURE
        vec4 sample = mix(texture2D(texture_previous, vertex_uv), texture2D(texture, vertex_uv), animation_time_texture);
        gl_FragColor = vec4(clamp(diffuse, 0.2, 1.) * sample.rgb, 1.0);
    #else
        gl_FragColor = vec4(clamp(diffuse, 0.2, 1.) * vertex_color.rgb, vertex_color.a);
    #endif // USE_TEXTURE
    #endif // AS_LINE
    #endif // USE_RGB
#endif //DEFAULT_SHADING

#ifdef LAMBERT_SHADING
    #include <clipping_planes_fragment>

	vec4 diffuseColor = vec4( vec3(1,1,1), opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive * emissiveIntensity;

	#include <logdepthbuf_fragment>
	#include <map_fragment>
	//#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <specularmap_fragment>
	#include <emissivemap_fragment>

	// accumulation
	reflectedLight.indirectDiffuse = getAmbientLightIrradiance( ambientLightColor );

	#include <lightmap_fragment>

	reflectedLight.indirectDiffuse *= BRDF_Diffuse_Lambert( diffuseColor.rgb );

	#ifdef DOUBLE_SIDED
		reflectedLight.directDiffuse = ( gl_FrontFacing ) ? vLightFront : vLightBack;
	#else
		reflectedLight.directDiffuse = vLightFront;
	#endif

	reflectedLight.directDiffuse *= BRDF_Diffuse_Lambert( diffuseColor.rgb ) * getShadowMask();

	// modulation
	#include <aomap_fragment>

	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

	#include <envmap_fragment>

	gl_FragColor = vec4( outgoingLight, diffuseColor.a );

	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>

#endif //LAMBERT_SHADING

#ifdef PHONG_SHADING
    #include <clipping_planes_fragment>

	vec4 diffuseColor = vec4( vec3(1,1,1), opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive * emissiveIntensity;

	#include <logdepthbuf_fragment>
	#include <map_fragment>
	//#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	//normal = -normal;
	#include <emissivemap_fragment>

	// accumulation
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>

	// modulation
	#include <aomap_fragment>

	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;

	#include <envmap_fragment>

	gl_FragColor = vec4( outgoingLight, diffuseColor.a );

	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
#endif //PHONG_SHADING

#ifdef PHYSICAL_SHADING
	#include <clipping_planes_fragment>
	
	vec4 diffuseColor = vec4( vec3(1,1,1), opacity );
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive * emissiveIntensity;

	#include <logdepthbuf_fragment>
	#include <map_fragment>
	//#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>

	// accumulation
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>

	// modulation
	#include <aomap_fragment>

	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	gl_FragColor = vec4( outgoingLight, diffuseColor.a );

	#include <tonemapping_fragment>
	#include <encodings_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
#endif //PHYSICAL_SHADING
}
