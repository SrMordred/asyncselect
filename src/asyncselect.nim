import macros

macro asyncselect*( select_body: untyped ): untyped = 
    expectKind(select_body, nnkStmtList)

    var select_stmt_list = newStmtList()

    for s in select_body:
        case s.kind:
            of nnkInfix:  # future_var as future_result:
                # Expecting 4 args 
                # future_var as future_result:
                #   stmts
                # -> Ident "as", Ident "future_var", Ident "future_result", StmtList
                expectLen s, 4
                let future_var_to_await = s[1]
                let future_var_result = s[2]
                let future_stmt_list = s[3]

                # if future_var_to_await.finished:
                #   var future_var_result = future_var_to_await.read
                #   `stmts`
                #   break

                var branch_stmt = newStmtList(
                    newIfStmt( # if
                        (
                            newDotExpr( future_var_to_await, newIdentNode("finished") ), # future_var_to_await.finished
                            newStmtList( 
                                nnkVarSection.newTree( 
                                    newIdentDefs( future_var_result, newEmptyNode(), newDotExpr( future_var_to_await, newIdentNode("read") ) ), # var future_var_result = future_var_to_await.read
                                ),
                                future_stmt_list, # selected case `body`
                                nnkBreakStmt.newTree(newEmptyNode()), # break
                            )
                        )
                    )
                )
                select_stmt_list.add( branch_stmt )
                discard

            of nnkCall: # future_var:
                # Expecting 2 args 
                # future_var:
                #   `stmts`
                # -> Ident "future_var", StmtList
                expectLen s, 2
                let future_var_to_await = s[0]
                let future_stmt_list = s[1]

                # if future_var_to_await.finished:
                #    `stmts`
                #    break
                var branch_stmt = newStmtList(
                    newIfStmt( # if
                        (
                            newDotExpr( future_var_to_await, newIdentNode("finished") ), # future_var_to_await.finished
                            newStmtList(
                                future_stmt_list, # selected case `body`
                                nnkBreakStmt.newTree(newEmptyNode()) # break
                            )
                        )
                    )
                )

                select_stmt_list.add( branch_stmt )
            else:
                raiseAssert( "Invalid statement type: expected 'nnkInfix' or 'nnkCall' got " & $s.type )
    
    select_stmt_list.add( newCall( newIdentNode("poll") ) ) # poll()

    # while true:
    #    `select_stmt_list`
    result = newStmtList(
        nnkWhileStmt.newTree(
            newIdentNode("true"),
            newStmtList(
                select_stmt_list
            )
        )
    );