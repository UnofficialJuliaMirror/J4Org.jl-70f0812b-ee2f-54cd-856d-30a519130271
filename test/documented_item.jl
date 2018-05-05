import J4Org:
    create_documented_item,
    tokenized,
    find_tag,
    org_string_comment,
    org_string_code,
    tag_idx


@testset "documented_item" begin
    filename="$(dirname(@__FILE__))/code_examples/basic.jl"
    t=tokenized(readstring(filename))
    r = find_tag(t,1)
end;

@testset "di_real_code_1" begin
    filename="$(dirname(@__FILE__))/code_examples/real_code_1.jl"
    t=tokenized(readstring(filename))
    r=find_tag(t,1)
    di=create_documented_item(t,tag_idx(r),filename=filename)
    @test org_string_comment(di,[di],[di],"","BoxingModule") == "#+BEGIN_QUOTE\nA *central* structure containing documented item\n#+END_QUOTE\n"
    @test org_string_code(di) == "#+BEGIN_SRC julia :eval never :exports code\nstruct Documented_Item\n#+END_SRC\n"

    r=find_tag(t,8)
    di=create_documented_item(t,tag_idx(r),filename=filename)
    @test org_string_comment(di,[di],[di],"","BoxingModule") == ""
    @test org_string_code(di) == "#+BEGIN_SRC julia :eval never :exports code\nfilename(di::Documented_Item)::String\n#+END_SRC\n"
end; 



@testset "di_real_code_problematic_1" begin
    filename="$(dirname(@__FILE__))/code_examples/real_code_problematic_1.jl"

    tok=tokenized(readstring(filename))

    idx=1
    extracted_tag = extract_tag(tok,idx)
    @assert extracted_tag != nothing
    idx=idx+1
    doc=extract_comment(tok,idx)
end; 




@testset "enum" begin
    filename="$(dirname(@__FILE__))/code_examples/enum.jl"
    t=tokenized(readstring(filename))
    r=find_tag(t,1)
    di=create_documented_item(t,tag_idx(r),filename=filename)
    @test org_string_comment(di,[di],[di],"","BoxingModule") == "#+BEGIN_QUOTE\nThis is an enum example [[target][@enum Alpha]]\n#+END_QUOTE\n"
    @test org_string_code(di) == "#+BEGIN_SRC julia :eval never :exports code\n@enum Alpha A  B=1 C\n#+END_SRC\n"
 end;



@testset "variable" begin
    filename="$(dirname(@__FILE__))/code_examples/variable.jl"
    t=tokenized(readstring(filename))
    r=find_tag(t,1)
    di=create_documented_item(t,tag_idx(r),filename=filename)
    @test org_string_comment(di,[di],[di],"","BoxingModule") == "#+BEGIN_QUOTE\nThis is an variable example [[target][variable A]]\n#+END_QUOTE\n"
    @test org_string_code(di) == "#+BEGIN_SRC julia :eval never :exports code\nA\n#+END_SRC\n"
 end;
