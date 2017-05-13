Hibernate: SELECT
             '合计'      AS '科室名称',
             sum(上期金额) AS '上期金额',
             sum(入库金额) AS '入库金额',
             sum(报损金额) AS '报损金额',
             sum(退库金额) AS '退库金额',
             sum(销售金额) AS '销售金额',
             sum(期末金额) AS '期末金额'
           FROM (SELECT *
                 FROM (SELECT
                         storeDept.name1                                                                   AS '科室名称',
                         storeDept.num                                                                     AS '药品编号',
                         storeDept.name                                                                    AS '药品名称',
                         storeDept.spec                                                                    AS '规格',
                         storeDept.unit                                                                    AS '单位',
                         isnull(lastRuKu.ruKuCount, 0) - isnull(lastBaoSun.baoSunCount, 0) -
                         isnull(xiaoshoumidden.xiaoshoumiddencount, 0) - isnull(lastTuiKu.tuiKuCount, 0)   AS '上期数量',
                         convert(DECIMAL(18, 2), storeDept.unit_Price)                                     AS '上期单价',
                         convert(DECIMAL(20, 2), (isnull(lastRuKu.ruKuCount, 0) - isnull(lastBaoSun.baoSunCount, 0) -
                                                  isnull(xiaoshoumidden.xiaoshoumiddencount, 0) -
                                                  isnull(lastTuiKu.tuiKuCount, 0)) * storeDept.unit_Price) AS '上期金额',
                         isnull(ruKu.ruKuCount, 0)                                                         AS '入库数量',
                         convert(DECIMAL(18, 2), isnull(ruKu.unitPrice, 0))                                AS '入库单价',
                         convert(DECIMAL(20, 2), isnull(ruKu.ruKuCount, 0) * storeDept.unit_Price)         AS '入库金额',
                         isnull(baoSun.baoSunCount, 0)                                                     AS '报损数量',
                         convert(DECIMAL(18, 2), storeDept.unit_Price)                                     AS '报损单价',
                         convert(DECIMAL(20, 2), isnull(baoSun.baoSunCount, 0) * storeDept.unit_Price)     AS '报损金额',
                         isnull(tuiKu.tuiKuCount, 0)                                                       AS '退库数量',
                         convert(DECIMAL(18, 2), isnull(tuiKu.unitPrice, 0))                               AS '退库单价',
                         convert(DECIMAL(20, 2), isnull(tuiKu.tuiKuCount, 0) * storeDept.unit_Price)       AS '退库金额',
                         isnull(xiaoshou.xiaoshoucount, 0)                                                 AS '销售数量',
                         convert(DECIMAL(18, 2), isnull(xiaoshou.xiaoshouprice, 0))                        AS '销售单价',
                         isnull(xiaoshou.xiaoshoutotal, 0)                                                 AS '销售金额',
                         (isnull(lastRuKu.ruKuCount, 0) - isnull(lastBaoSun.baoSunCount, 0) -
                          isnull(xiaoshou.xiaoshoucount, 0) - isnull(lastTuiKu.tuiKuCount, 0)) +
                         isnull(ruKu.ruKuCount, 0) - isnull(baoSun.baoSunCount, 0) -
                         isnull(xiaoshoumidden.xiaoshoumiddencount, 0) - isnull(tuiKu.tuiKuCount, 0)       AS '期末数量',
                         convert(DECIMAL(18, 2), storeDept.unit_Price)                                     AS '期末单价',
                         convert(DECIMAL(20, 2), ((isnull(lastRuKu.ruKuCount, 0) - isnull(lastBaoSun.baoSunCount, 0) -
                                                   isnull(xiaoshou.xiaoshoucount, 0) - isnull(lastTuiKu.tuiKuCount, 0))
                                                  + isnull(ruKu.ruKuCount, 0) - isnull(baoSun.baoSunCount, 0) -
                                                  isnull(xiaoshoumidden.xiaoshoumiddencount, 0) -
                                                  isnull(tuiKu.tuiKuCount, 0)) * storeDept.unit_Price)     AS '期末金额'
                       FROM (SELECT DISTINCT
                               store_dept.num,
                               store_dept.name,
                               store_dept.vendor_name,
                               store_dept.spec,
                               store_dept.dept_id,
                               store_dept.unit_price,
                               store_dept.unit,
                               auth_dept.name AS 'name1'
                             FROM drug_store_dept store_dept LEFT JOIN T_DEPARTMENT auth_dept
                                 ON auth_dept.id = store_dept.dept_id
                             WHERE 1 = 1 AND auth_dept.name = '免疫规划所' AND store_dept.drug_type_id = '1'
                             GROUP BY store_dept.num, store_dept.name, store_dept.vendor_name, store_dept.spec,
                               store_dept.dept_id, store_dept.unit_price, store_dept.unit,
                               auth_dept.name) storeDept LEFT JOIN (SELECT DISTINCT
                                                                      authDept.name,
                                                                      issueDeptSon.num,
                                                                      issueDeptSon.drug_name,
                                                                      issueDeptSon.retail_price                  AS unitPrice,
                                                                      isnull(sum(issueDeptSon.drug_uumber),
                                                                             0)                                  AS rukuCount,
                                                                      isnull(sum(issueDeptSon.drug_money),
                                                                             0.00)                               AS totalPrice
                                                                    FROM drug_issue_dept issueDept RIGHT JOIN (SELECT *
                                                                                                               FROM
                                                                                                                 drug_trac_department) issueDeptSon
                                                                        ON issueDeptSon.drug_issue_dept_id =
                                                                           issueDept.id
                                                                      LEFT JOIN T_DEPARTMENT authDept
                                                                        ON authDept.id = issueDept.department_name
                                                                    WHERE 1 = 1 AND issueDept.drug_status = 0 AND
                                                                          authDept.name = '免疫规划所' AND
                                                                          maker_time < '2017-04-26'
                                                                    GROUP BY issueDeptSon.num, issueDeptSon.drug_name,
                                                                      issueDeptSon.retail_price, authDept.name) lastRuKu
                           ON lastRuKu.num = storeDept.num AND lastRuKu.unitPrice = storeDept.unit_price
                         LEFT JOIN (SELECT DISTINCT
                                      approve.auth_dept,
                                      deptLoss.num,
                                      approve.drug_name,
                                      isnull(sum(convert(INT, approve.drug_loss_number)), 0) AS baoSunCount,
                                      isnull(sum(convert(FLOAT, approve.drug_money)), 0.00)  AS totalPrice
                                    FROM drug_department_loss_approve approve LEFT JOIN (SELECT
                                                                                           id,
                                                                                           num
                                                                                         FROM
                                                                                           drug_department_loss_table) deptLoss
                                        ON deptLoss.id = approve.drug_department_loss_id
                                    WHERE 1 = 1 AND approve_result = '同意' AND approve.auth_dept = '免疫规划所' AND
                                          drug_loss_time < '2017/04/26'
                                    GROUP BY approve.auth_dept, deptLoss.num, approve.drug_name) lastBaoSun
                           ON lastBaoSun.num = storeDept.num
                         LEFT JOIN (SELECT DISTINCT
                                      dept.name,
                                      appSon.num,
                                      appSon.drug_name,
                                      appSon.wholesale_price               AS unitPrice,
                                      isnull(sum(appSon.drug_uumber), 0)   AS xiaBoCount,
                                      isnull(sum(appSon.drug_money), 0.00) AS totalPrice
                                    FROM dept_drug_App app LEFT JOIN dept_drug_App_detail appSon
                                        ON appSon.drug_issue_dept_id = app.id
                                      LEFT JOIN (SELECT
                                                   id,
                                                   dept_id
                                                 FROM drug_store_dept) store_dept
                                        ON appSon.centre_storage_id = store_dept.id
                                      LEFT JOIN (SELECT
                                                   id,
                                                   name
                                                 FROM T_DEPARTMENT) dept ON dept.id = store_dept.dept_id
                                    WHERE 1 = 1 AND app.drug_status = 0 AND dept.name = '免疫规划所' AND
                                          maker_time < '2017-04-26'
                                    GROUP BY dept.name, appSon.num, appSon.drug_name, appSon.wholesale_price) lastXiaBo
                           ON lastXiaBo.num = storeDept.num AND lastXiaBo.unitPrice = storeDept.unit_price
                         LEFT JOIN (SELECT DISTINCT
                                      dept.name,
                                      refundingSon.num                                                AS num,
                                      isnull(sum(refundingSon.quantity), 0)                           AS tuiKuCount,
                                      refundingSon.unit_price                                         AS unitPrice,
                                      isnull(sum(refundingSon.quantity), 0) * refundingSon.unit_price AS totalPrice
                                    FROM drug_refunding_son refundingSon LEFT JOIN drug_refunding refunding
                                        ON refundingSon.drug_refunding_id = refunding.id
                                      LEFT JOIN (SELECT
                                                   id,
                                                   name
                                                 FROM T_DEPARTMENT) dept ON dept.id = refundingSon.return_deptId
                                    WHERE 1 = 1 AND dept.name = '免疫规划所' AND refunding.return_date < '2017-04-26'
                                    GROUP BY refundingSon.num, refundingSon.unit_price, dept.name) lastTuiKu
                           ON lastTuiKu.num = storeDept.num AND lastTuiKu.unitPrice = storeDept.unit_price
                         LEFT JOIN (SELECT DISTINCT
                                      authDept.name,
                                      issueDeptSon.num,
                                      issueDeptSon.drug_name,
                                      issueDeptSon.retail_price                AS unitPrice,
                                      isnull(sum(issueDeptSon.drug_uumber), 0) AS rukuCount,
                                      sum(issueDeptSon.drug_money)             AS totalPrice
                                    FROM drug_issue_dept issueDept RIGHT JOIN (SELECT *
                                                                               FROM drug_trac_department) issueDeptSon
                                        ON issueDeptSon.drug_issue_dept_id = issueDept.id
                                      LEFT JOIN T_DEPARTMENT authDept ON authDept.id = issueDept.department_name
                                    WHERE 1 = 1 AND issueDept.drug_status = 0 AND authDept.name = '免疫规划所' AND
                                          maker_time >= '2017-04-26' AND maker_time <= '2017-04-26'
                                    GROUP BY issueDeptSon.num, issueDeptSon.drug_name, issueDeptSon.retail_price,
                                      authDept.name) ruKu
                           ON ruKu.num = storeDept.num AND ruKu.unitPrice = storeDept.unit_price
                         LEFT JOIN (SELECT
                                      approve.auth_dept,
                                      deptLoss.num,
                                      approve.drug_name,
                                      isnull(sum(convert(INT, approve.drug_loss_number)), 0) AS baoSunCount
                                    FROM drug_department_loss_approve approve LEFT JOIN (SELECT
                                                                                           id,
                                                                                           num
                                                                                         FROM
                                                                                           drug_department_loss_table) deptLoss
                                        ON deptLoss.id = approve.drug_department_loss_id
                                    WHERE 1 = 1 AND approve_result = '同意' AND approve.auth_dept = '免疫规划所' AND
                                          drug_loss_time >= '2017/04/26' AND drug_loss_time <= '2017/04/26'
                                    GROUP BY approve.auth_dept, deptLoss.num, approve.drug_name) baoSun
                           ON baoSun.num = storeDept.num
                         LEFT JOIN (SELECT DISTINCT
                                      dept.name,
                                      appSon.num,
                                      appSon.drug_name,
                                      appSon.wholesale_price               AS unitPrice,
                                      isnull(sum(appSon.drug_uumber), 0)   AS xiaBoCount,
                                      isnull(sum(appSon.drug_money), 0.00) AS totalPrice
                                    FROM dept_drug_App app LEFT JOIN dept_drug_App_detail appSon
                                        ON appSon.drug_issue_dept_id = app.id
                                      LEFT JOIN (SELECT
                                                   id,
                                                   dept_id
                                                 FROM drug_store_dept) store_dept
                                        ON appSon.centre_storage_id = store_dept.id
                                      LEFT JOIN (SELECT
                                                   id,
                                                   name
                                                 FROM T_DEPARTMENT) dept ON dept.id = store_dept.dept_id
                                    WHERE 1 = 1 AND app.drug_status = 0 AND dept.name = '免疫规划所' AND
                                          maker_time >= '2017-04-26' AND maker_time <= '2017-04-26'
                                    GROUP BY dept.name, appSon.num, appSon.drug_name, appSon.wholesale_price) xiaBo
                           ON xiaBo.num = storeDept.num AND xiaBo.unitPrice = storeDept.unit_price
                         LEFT JOIN (SELECT DISTINCT
                                      dept.name,
                                      refundingSon.num                                                AS num,
                                      isnull(sum(refundingSon.quantity), 0)                           AS tuiKuCount,
                                      refundingSon.unit_price                                         AS unitPrice,
                                      isnull(sum(refundingSon.quantity), 0) * refundingSon.unit_price AS totalPrice
                                    FROM drug_refunding_son refundingSon LEFT JOIN drug_refunding refunding
                                        ON refundingSon.drug_refunding_id = refunding.id
                                      LEFT JOIN (SELECT
                                                   id,
                                                   name
                                                 FROM T_DEPARTMENT) dept ON dept.id = refundingSon.return_deptId
                                    WHERE 1 = 1 AND dept.name = '免疫规划所' AND refunding.return_date >= '2017-04-26' AND
                                          refunding.return_date <= '2017-04-26'
                                    GROUP BY refundingSon.num, refundingSon.unit_price, dept.name) tuiKu
                           ON tuiKu.num = storeDept.num AND tuiKu.unitPrice = storeDept.unit_price
                         LEFT JOIN (SELECT
                                      d.num                                       AS num,
                                      sum(isnull(CONVERT(INT, b.store_count), 0)) AS xiaoshoucount,
                                      b.unit_price                                   xiaoshouprice,
                                      sum(b.total_price)                          AS xiaoshoutotal
                                    FROM recipe_order AS a LEFT JOIN recipe_store_order AS b
                                        ON a.order_id = b.medical_order_id
                                      LEFT JOIN drug_collar_indeed AS c ON c.recipe_order_id = b.medical_order_id
                                      LEFT JOIN drug_trac_department AS d ON d.id = b.drug_id
                                      LEFT JOIN T_DEPARTMENT AS f ON f.id = b.store_dept_id
                                    WHERE a.statu = 1 AND CONVERT(VARCHAR(10), c.grant_date, 120) >= '2017-04-26' AND
                                          CONVERT(VARCHAR(10), c.grant_date, 120) <= '2017-04-26'
                                    GROUP BY b.unit_price, d.num) xiaoshou
                           ON xiaoshou.num = storeDept.num AND xiaoshou.xiaoshouprice = storeDept.unit_price
                         LEFT JOIN (SELECT
                                      d.num                                       AS num,
                                      sum(isnull(CONVERT(INT, b.store_count), 0)) AS xiaoshoucount,
                                      b.unit_price                                   xiaoshouprice,
                                      sum(b.total_price)                          AS xiaoshoutotal
                                    FROM recipe_order AS a LEFT JOIN recipe_store_order AS b
                                        ON a.order_id = b.medical_order_id
                                      LEFT JOIN drug_collar_indeed AS c ON c.recipe_order_id = b.medical_order_id
                                      LEFT JOIN drug_trac_department AS d ON d.id = b.drug_id
                                      LEFT JOIN T_DEPARTMENT AS f ON f.id = b.store_dept_id
                                    WHERE a.statu = 1 AND CONVERT(VARCHAR(10), c.grant_date, 120) < '2017-04-26'
                                    GROUP BY b.unit_price, d.num) lastxiaoshou
                           ON lastxiaoshou.num = storeDept.num AND lastxiaoshou.xiaoshouprice = storeDept.unit_price
                         LEFT JOIN (SELECT
                                      d.num                                       AS num,
                                      sum(isnull(CONVERT(INT, b.store_count), 0)) AS xiaoshoumiddencount,
                                      b.unit_price                                   xiaoshoumiddenprice,
                                      sum(b.total_price)                          AS xiaoshoumiddentotal
                                    FROM recipe_order AS a LEFT JOIN recipe_store_order AS b
                                        ON a.order_id = b.medical_order_id
                                      LEFT JOIN drug_collar_indeed AS c ON c.recipe_order_id = b.medical_order_id
                                      LEFT JOIN drug_trac_department AS d ON d.id = b.drug_id
                                      LEFT JOIN T_DEPARTMENT AS f ON f.id = b.store_dept_id
                                    WHERE a.statu = 1 AND CONVERT(VARCHAR(10), c.grant_date, 120) < '2017-04-26'
                                    GROUP BY b.unit_price, d.num) xiaoshoumidden
                           ON xiaoshoumidden.num = storeDept.num AND
                              xiaoshoumidden.xiaoshoumiddenprice = storeDept.unit_price) a
                 WHERE
                   1 = 1 AND (a.上期数量 != 0 OR a.入库数量 != 0 OR a.报损数量 != 0 OR a.退库数量 != 0 OR a.销售数量 != 0 OR a.销售数量 != 0)) b
