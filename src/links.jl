
#+Links L:extract_links_string
#
# This function returns the list of links found in the string. It
# returns nothing if no link is found
#
# #+BEGIN_SRC julia
# s="# some text [[some_target][]] another one [[link_target][link_name]]\n and a last one [[a4][b1]]"
# J4Org.extract_links(s)
# #+END_SRC
#
# #+BEGIN_EXAMPLE
# 1-element Array{Tuple{String,String},1}:
#  ("some_target", "")         
# #+END_EXAMPLE
#
# *Caveat:* only use links of the forme ​"[​[something][]]", which are not
#           valid Org mode links, see [[doc_link_substituion][]]
#
# *Test link:* [[doc_link_substituion][]]
#
function extract_links(input::String)::Vector{Tuple{String,String}}
    # remove blalba "toremove" kmsdqkm (do not consider quoted links)
    input = replace(input,r"(\".*\")","")
    v=Vector{Tuple{String,String}}(0)
    
    match_link = r"\[\[(\w+)\]\[\]\]"
    m=match(match_link,input)

    if m==nothing
        return v
    end

    push!(v,(m[1],""))
    offset=m.offsets[end]+length(m[1])
    
    while (m=match(match_link,input,offset))!=nothing
        push!(v,(m[1],""))
        offset=m.offsets[end]+length(m[1])      
    end 
    
    v
end

#+Links
#
# This function is like [[extract_links_string][]], except that is
# process an array of [[Documented_Item][]]
#
function extract_links(di_array::Array{Documented_Item,1})::Vector{Tuple{String,String}}
    v=Vector{Tuple{String,String}}(0)

    for di in di_array
        v=vcat(v,extract_links(raw_string_doc(di)))
    end 

    v
end

#+Links
#
# This function clean extracted links by removing duplicates
#
# See: [[extract_links_string][]]
function clean_extracted_links(toClean::Vector{Tuple{String,String}})::Vector{Tuple{String,String}}
    # a priori sort is not necessary
    return unique(toClean)
end

#+Links
#
# Returns the indices of [[Documented_Item][]] containing the
# link_target (have a tag line with L:link_target)
#
# *Note:* a normal situation is to have zero or one indices. Several
# indices means that we do not have a unique target.
#
function get_items_with_link_target(link_target::String,di_array::Array{Documented_Item,1})::Vector{Int}
    v=Vector{Int}(0)
    const n = length(di_array)
    for i in 1:n
        if link_target==link(di_array[i])
            push!(v,i)
        end
    end 
    return v
end 

#+Links                                       L:doc_link_substituion
# From doc string performs links substitution
#
# - check if there are links in the doc, eventually return unmodified doc string 
# - for each link check if it exists in di_array
#   - yes, replace ​[​[link_target][]] by ​[​[link_prefix_link_target][identifier]] to create a valid OrgMode link.
#   - no,  replace ​[​[link_target][]] by _link_target_ to create an inactive link 
#
# *Note:* in order to do not interfere with org mode link we only process "links" of the form "[[something][]]"
#         see https://orgmode.org/manual/Link-format.html
#
# *Note:* to be able to write a "unactive" link, use C-x 8 RET 200b
#         (see: https://emacs.stackexchange.com/a/16702)
#
function doc_link_substituion(doc::String,di_array::Array{Documented_Item,1},link_prefix::String)::String
    # extract links 
    links = extract_links(doc)
    links=clean_extracted_links(links)
    
    if isempty(links)
        return doc
    end


    # for each links search its identifier
    const not_found = Int(-1)
    n_links = length(links)
    n_di_array = length(di_array)
    for k in 1:n_links
        first_occurence = not_found
        link_in_doc="[[$(first(links[k]))][]]"
        for i in 1:n_di_array
            if first(links[k])==link(di_array[i])
                first_occurence = i
                break;
            end
        end

        if first_occurence==not_found
            warning_message("Link target $(links[k]) not found")
            doc = replace(doc,link_in_doc,"_$(first(links[k]))_") # inactive link 
        else
            # Generate "readable part of the link"
            # start with the identifier
            identifier_for_link_k = identifier(di_array[first_occurence])

            if isempty(identifier_for_link_k)
                # if no identifier reuse the link first part (the target string)
                identifier_for_link_k=links[k][1]
            else
                # if the target has an identifier try to magnify it
                # - function add identifier()
                # - strucure add struct identifier
                # - ...
                if is_documented_function(di_array[first_occurence])
                    identifier_for_link_k=identifier_for_link_k*"(...)"
                elseif is_documented_structure(di_array[first_occurence])
                    identifier_for_link_k="struct "*identifier_for_link_k
                elseif is_documented_abstract_type(di_array[first_occurence])
                    identifier_for_link_k="abstract "*identifier_for_link_k
                elseif is_documented_enum_type(di_array[first_occurence])
                    identifier_for_link_k="@enum "*identifier_for_link_k
                end 
            end 
            links[k]=(links[k][1],identifier_for_link_k)
            
            # check for multi-occurrence
            for i in first_occurence+1:n_di_array
                if first(links[k])==link(di_array[i])
                    warning_message("multi-occurrences of target $(links[k]), $(create_file_org_link(di_array[first_occurence])) <-> $(create_file_org_link(di_array[i]))")
                end
            end  

            # perform substitution
            doc = replace(doc,link_in_doc,"[[$(link_prefix*first(links[k]))][$(last(links[k]))]]")
        end 
    end

    return doc
end 


