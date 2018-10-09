using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PastTextureHandler : MonoBehaviour {

    public Vector2Int TextureSize = new Vector2Int(1024, 1024);

    public Material WorkingMaterial = null;
    public Material Outputmaterial = null;

    RenderTexture tex1;
    RenderTexture tex2;
    
    bool chooseTex1 = true;


	void OnEnable ()
    {
        tex1 = new RenderTexture(this.TextureSize.x, this.TextureSize.y, 0, RenderTextureFormat.ARGBInt);
        tex2 = new RenderTexture(this.TextureSize.x, this.TextureSize.y, 0, RenderTextureFormat.ARGBInt);
        
        this.WorkingMaterial.SetTexture("_PastTex", this.tex2);
        this.WorkingMaterial.SetVector("_Resolution", new Vector4(this.TextureSize.x, this.TextureSize.y));
        this.Outputmaterial.mainTexture = tex1;
    }

    private void OnDisable()
    {
        tex1.Release();
        tex2.Release();
    }

    private void Update()
    {
        this.Step();
    }

    private void Step()
    {
        RenderTexture source = this.chooseTex1 ? this.tex1 : this.tex2;
        RenderTexture destination = !this.chooseTex1 ? this.tex1 : this.tex2;
        this.WorkingMaterial.SetTexture("_PastTex", source);
        Graphics.Blit(source, destination, this.WorkingMaterial);

        this.chooseTex1 = !this.chooseTex1;
    }

    public RenderTexture GetTexture()
    {
        return tex1;
    }
}
