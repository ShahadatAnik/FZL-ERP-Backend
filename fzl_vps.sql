PGDMP                  	    |            fzl %   14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)     16.4 (Ubuntu 16.4-1.pgdg22.04+1) �   �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    34533    fzl    DATABASE     k   CREATE DATABASE fzl WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';
    DROP DATABASE fzl;
                postgres    false                        2615    34534 
   commercial    SCHEMA        CREATE SCHEMA commercial;
    DROP SCHEMA commercial;
                postgres    false                        2615    34535    delivery    SCHEMA        CREATE SCHEMA delivery;
    DROP SCHEMA delivery;
                postgres    false                        2615    34536    drizzle    SCHEMA        CREATE SCHEMA drizzle;
    DROP SCHEMA drizzle;
                postgres    false                        2615    34537    hr    SCHEMA        CREATE SCHEMA hr;
    DROP SCHEMA hr;
                postgres    false            	            2615    34538    lab_dip    SCHEMA        CREATE SCHEMA lab_dip;
    DROP SCHEMA lab_dip;
                postgres    false            
            2615    34539    material    SCHEMA        CREATE SCHEMA material;
    DROP SCHEMA material;
                postgres    false                        2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                postgres    false            �           0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                   postgres    false    15                        2615    34540    purchase    SCHEMA        CREATE SCHEMA purchase;
    DROP SCHEMA purchase;
                postgres    false                        2615    34541    slider    SCHEMA        CREATE SCHEMA slider;
    DROP SCHEMA slider;
                postgres    false                        2615    34542    thread    SCHEMA        CREATE SCHEMA thread;
    DROP SCHEMA thread;
                postgres    false                        2615    34543    zipper    SCHEMA        CREATE SCHEMA zipper;
    DROP SCHEMA zipper;
                postgres    false            �           1247    34545    batch_status    TYPE     m   CREATE TYPE zipper.batch_status AS ENUM (
    'pending',
    'completed',
    'rejected',
    'cancelled'
);
    DROP TYPE zipper.batch_status;
       zipper          postgres    false    14            �           1247    34554    print_in_enum    TYPE     `   CREATE TYPE zipper.print_in_enum AS ENUM (
    'portrait',
    'landscape',
    'break_down'
);
     DROP TYPE zipper.print_in_enum;
       zipper          postgres    false    14            �           1247    34562    slider_starting_section_enum    TYPE     �   CREATE TYPE zipper.slider_starting_section_enum AS ENUM (
    'die_casting',
    'slider_assembly',
    'coloring',
    '---'
);
 /   DROP TYPE zipper.slider_starting_section_enum;
       zipper          postgres    false    14            �           1247    34572    swatch_status_enum    TYPE     a   CREATE TYPE zipper.swatch_status_enum AS ENUM (
    'pending',
    'approved',
    'rejected'
);
 %   DROP TYPE zipper.swatch_status_enum;
       zipper          postgres    false    14            E           1255    34579 /   sfg_after_commercial_pi_entry_delete_function()    FUNCTION     (  CREATE FUNCTION commercial.sfg_after_commercial_pi_entry_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.sfg SET
        pi = pi - OLD.pi_cash_quantity
    WHERE uuid = OLD.sfg_uuid;

    UPDATE thread.order_entry SET
        pi = pi - OLD.pi_cash_quantity
    WHERE uuid = OLD.thread_order_entry_uuid;

    -- UPDATE pi_cash table and remove the particular order_info_uuids from the array if there is no sfg_uuid in pi_cash_entry
    IF OLD.sfg_uuid IS NOT NULL THEN 
    UPDATE commercial.pi_cash
    SET
        order_info_uuids = COALESCE(
            (
                SELECT jsonb_agg(elem)
                FROM (
                    SELECT elem
                    FROM jsonb_array_elements_text(order_info_uuids::jsonb) elem
                    WHERE elem != (
                        SELECT DISTINCT vod.order_info_uuid::text 
                        FROM zipper.v_order_details vod 
                        WHERE vod.order_description_uuid = (
                            SELECT oe.order_description_uuid 
                            FROM zipper.order_entry oe 
                            WHERE oe.uuid = OLD.sfg_uuid
                        )
                    )
                ) subquery
            ), '[]'::jsonb
        )
    WHERE EXISTS (
        -- Check existence after the deletion is complete
        SELECT 1
        FROM zipper.sfg sfg
        LEFT JOIN zipper.order_entry oe ON sfg.order_entry_uuid = oe.uuid
        LEFT JOIN zipper.v_order_details vod ON oe.order_description_uuid = vod.order_description_uuid
        WHERE sfg.uuid = OLD.sfg_uuid
    );
    END IF;

    -- If the pi_cash_entry is deleted, then delete the pi_cash_entry from pi_cash table for thread
    IF OLD.thread_order_entry_uuid IS NOT NULL THEN
    UPDATE commercial.pi_cash
    SET
        thread_order_info_uuids = COALESCE(
            (
                SELECT jsonb_agg(elem)
                FROM (
                    SELECT elem
                    FROM jsonb_array_elements_text(thread_order_info_uuids::jsonb) elem
                    WHERE elem != (
                        SELECT DISTINCT toi.uuid::text 
                        FROM thread.order_info toi 
                        WHERE toi.uuid = (
                            SELECT toe.order_info_uuid 
                            FROM thread.order_entry toe 
                            WHERE toe.uuid = OLD.thread_order_entry_uuid
                        )
                    )
                ) subquery
            ), '[]'::jsonb
        )
    WHERE EXISTS (
        -- Check existence after the deletion is complete
        SELECT 1
        FROM thread.order_entry toe
        LEFT JOIN thread.order_info toi ON toe.order_info_uuid = toi.uuid
        WHERE toe.uuid = OLD.thread_order_entry_uuid
    );
    END IF;

    RETURN OLD;
END;
$$;
 J   DROP FUNCTION commercial.sfg_after_commercial_pi_entry_delete_function();
    
   commercial          postgres    false    5            F           1255    34580 /   sfg_after_commercial_pi_entry_insert_function()    FUNCTION     r  CREATE FUNCTION commercial.sfg_after_commercial_pi_entry_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.sfg SET
        pi = pi + NEW.pi_cash_quantity
    WHERE uuid = NEW.sfg_uuid;

    UPDATE thread.order_entry SET
        pi = pi + NEW.pi_cash_quantity
    WHERE uuid = NEW.thread_order_entry_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION commercial.sfg_after_commercial_pi_entry_insert_function();
    
   commercial          postgres    false    5            M           1255    34581 /   sfg_after_commercial_pi_entry_update_function()    FUNCTION     �  CREATE FUNCTION commercial.sfg_after_commercial_pi_entry_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.sfg SET
        pi = pi + NEW.pi_cash_quantity - OLD.pi_cash_quantity
    WHERE uuid = NEW.sfg_uuid;

    UPDATE thread.order_entry SET
        pi = pi + NEW.pi_cash_quantity - OLD.pi_cash_quantity
    WHERE uuid = NEW.thread_order_entry_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION commercial.sfg_after_commercial_pi_entry_update_function();
    
   commercial          postgres    false    5            P           1255    34582 2   packing_list_after_challan_entry_delete_function()    FUNCTION     +  CREATE FUNCTION delivery.packing_list_after_challan_entry_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update delivery,packing_list
    UPDATE delivery.packing_list
    SET
        challan_uuid = NULL
    WHERE uuid = OLD.packing_list_uuid;
    RETURN OLD;
END;
$$;
 K   DROP FUNCTION delivery.packing_list_after_challan_entry_delete_function();
       delivery          postgres    false    6            Q           1255    34583 2   packing_list_after_challan_entry_insert_function()    FUNCTION     7  CREATE FUNCTION delivery.packing_list_after_challan_entry_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update delivery,packing_list
    UPDATE delivery.packing_list
    SET
        challan_uuid = NEW.challan_uuid
    WHERE uuid = NEW.packing_list_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.packing_list_after_challan_entry_insert_function();
       delivery          postgres    false    6            R           1255    34584 2   packing_list_after_challan_entry_update_function()    FUNCTION     7  CREATE FUNCTION delivery.packing_list_after_challan_entry_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update delivery,packing_list
    UPDATE delivery.packing_list
    SET
        challan_uuid = NEW.challan_uuid
    WHERE uuid = NEW.packing_list_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.packing_list_after_challan_entry_update_function();
       delivery          postgres    false    6            S           1255    34585 2   sfg_after_challan_receive_status_delete_function()    FUNCTION     �  CREATE FUNCTION delivery.sfg_after_challan_receive_status_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse + CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END,
        delivered = delivered - CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END
    WHERE uuid = OLD.sfg_uuid;
    RETURN OLD;
END;
$$;
 K   DROP FUNCTION delivery.sfg_after_challan_receive_status_delete_function();
       delivery          postgres    false    6            T           1255    34586 2   sfg_after_challan_receive_status_insert_function()    FUNCTION     �  CREATE FUNCTION delivery.sfg_after_challan_receive_status_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END,
        delivered = delivered + CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.sfg_after_challan_receive_status_insert_function();
       delivery          postgres    false    6            U           1255    34587 2   sfg_after_challan_receive_status_update_function()    FUNCTION     -  CREATE FUNCTION delivery.sfg_after_challan_receive_status_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END + CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END,
        delivered = delivered + CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END - CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.sfg_after_challan_receive_status_update_function();
       delivery          postgres    false    6            V           1255    34588 .   sfg_after_packing_list_entry_delete_function()    FUNCTION     Q  CREATE FUNCTION delivery.sfg_after_packing_list_entry_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - OLD.quantity,
        finishing_prod = finishing_prod + OLD.quantity
    WHERE uuid = OLD.sfg_uuid;
    RETURN OLD;
END;
$$;
 G   DROP FUNCTION delivery.sfg_after_packing_list_entry_delete_function();
       delivery          postgres    false    6            W           1255    34589 .   sfg_after_packing_list_entry_insert_function()    FUNCTION     Q  CREATE FUNCTION delivery.sfg_after_packing_list_entry_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse + NEW.quantity,
        finishing_prod = finishing_prod - NEW.quantity
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 G   DROP FUNCTION delivery.sfg_after_packing_list_entry_insert_function();
       delivery          postgres    false    6            X           1255    34590 .   sfg_after_packing_list_entry_update_function()    FUNCTION     o  CREATE FUNCTION delivery.sfg_after_packing_list_entry_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - OLD.quantity + NEW.quantity,
        finishing_prod = finishing_prod + OLD.quantity - NEW.quantity
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 G   DROP FUNCTION delivery.sfg_after_packing_list_entry_update_function();
       delivery          postgres    false    6            Y           1255    34591 +   material_stock_after_material_info_delete()    FUNCTION     �   CREATE FUNCTION material.material_stock_after_material_info_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM material.stock
    WHERE material_uuid = OLD.uuid;
    RETURN OLD;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_info_delete();
       material          postgres    false    10            Z           1255    34592 +   material_stock_after_material_info_insert()    FUNCTION     �   CREATE FUNCTION material.material_stock_after_material_info_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO material.stock
       (uuid, material_uuid)
    VALUES
         (NEW.uuid, NEW.uuid);
    RETURN NEW;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_info_insert();
       material          postgres    false    10            :           1255    34593 *   material_stock_after_material_trx_delete()    FUNCTION     l  CREATE FUNCTION material.material_stock_after_material_trx_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    stock = stock + OLD.trx_quantity,
    lab_dip = lab_dip - CASE WHEN OLD.trx_to = 'lab_dip' THEN OLD.trx_quantity ELSE 0 END,
    tape_making = tape_making - CASE WHEN OLD.trx_to = 'tape_making' THEN OLD.trx_quantity ELSE 0 END,
    coil_forming = coil_forming - CASE WHEN OLD.trx_to = 'coil_forming' THEN OLD.trx_quantity ELSE 0 END,
    dying_and_iron = dying_and_iron - CASE WHEN OLD.trx_to = 'dying_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_gapping = m_gapping - CASE WHEN OLD.trx_to = 'm_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_gapping = v_gapping - CASE WHEN OLD.trx_to = 'v_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_molding = v_teeth_molding - CASE WHEN OLD.trx_to = 'v_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_molding = m_teeth_molding - CASE WHEN OLD.trx_to = 'm_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing - CASE WHEN OLD.trx_to = 'teeth_assembling_and_polishing' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning - CASE WHEN OLD.trx_to = 'm_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning - CASE WHEN OLD.trx_to = 'v_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    plating_and_iron = plating_and_iron - CASE WHEN OLD.trx_to = 'plating_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_sealing = m_sealing - CASE WHEN OLD.trx_to = 'm_sealing' THEN OLD.trx_quantity ELSE 0 END,
    v_sealing = v_sealing - CASE WHEN OLD.trx_to = 'v_sealing' THEN OLD.trx_quantity ELSE 0 END,
    n_t_cutting = n_t_cutting - CASE WHEN OLD.trx_to = 'n_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    v_t_cutting = v_t_cutting - CASE WHEN OLD.trx_to = 'v_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_stopper = m_stopper - CASE WHEN OLD.trx_to = 'm_stopper' THEN OLD.trx_quantity ELSE 0 END,
    v_stopper = v_stopper - CASE WHEN OLD.trx_to = 'v_stopper' THEN OLD.trx_quantity ELSE 0 END,
    n_stopper = n_stopper - CASE WHEN OLD.trx_to = 'n_stopper' THEN OLD.trx_quantity ELSE 0 END,
    cutting = cutting - CASE WHEN OLD.trx_to = 'cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing - CASE WHEN OLD.trx_to = 'm_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing - CASE WHEN OLD.trx_to = 'v_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing - CASE WHEN OLD.trx_to = 'n_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing - CASE WHEN OLD.trx_to = 's_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    die_casting = die_casting - CASE WHEN OLD.trx_to = 'die_casting' THEN OLD.trx_quantity ELSE 0 END,
    slider_assembly = slider_assembly - CASE WHEN OLD.trx_to = 'slider_assembly' THEN OLD.trx_quantity ELSE 0 END,
    coloring = coloring - CASE WHEN OLD.trx_to = 'coloring' THEN OLD.trx_quantity ELSE 0 END

    WHERE material_uuid = OLD.material_uuid;
    RETURN OLD;
END;
$$;
 C   DROP FUNCTION material.material_stock_after_material_trx_delete();
       material          postgres    false    10            ?           1255    34594 *   material_stock_after_material_trx_insert()    FUNCTION     l  CREATE FUNCTION material.material_stock_after_material_trx_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    stock = stock -  NEW.trx_quantity,
    lab_dip = lab_dip + CASE WHEN NEW.trx_to = 'lab_dip' THEN NEW.trx_quantity ELSE 0 END,
    tape_making = tape_making + CASE WHEN NEW.trx_to = 'tape_making' THEN NEW.trx_quantity ELSE 0 END,
    coil_forming = coil_forming + CASE WHEN NEW.trx_to = 'coil_forming' THEN NEW.trx_quantity ELSE 0 END,
    dying_and_iron = dying_and_iron + CASE WHEN NEW.trx_to = 'dying_and_iron' THEN NEW.trx_quantity ELSE 0 END,
    m_gapping = m_gapping + CASE WHEN NEW.trx_to = 'm_gapping' THEN NEW.trx_quantity ELSE 0 END,
    v_gapping = v_gapping + CASE WHEN NEW.trx_to = 'v_gapping' THEN NEW.trx_quantity ELSE 0 END,
    v_teeth_molding = v_teeth_molding + CASE WHEN NEW.trx_to = 'v_teeth_molding' THEN NEW.trx_quantity ELSE 0 END,
    m_teeth_molding = m_teeth_molding + CASE WHEN NEW.trx_to = 'm_teeth_molding' THEN NEW.trx_quantity ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + CASE WHEN NEW.trx_to = 'teeth_assembling_and_polishing' THEN NEW.trx_quantity ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + CASE WHEN NEW.trx_to = 'm_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + CASE WHEN NEW.trx_to = 'v_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END,
    plating_and_iron = plating_and_iron + CASE WHEN NEW.trx_to = 'plating_and_iron' THEN NEW.trx_quantity ELSE 0 END,
    m_sealing = m_sealing + CASE WHEN NEW.trx_to = 'm_sealing' THEN NEW.trx_quantity ELSE 0 END,
    v_sealing = v_sealing + CASE WHEN NEW.trx_to = 'v_sealing' THEN NEW.trx_quantity ELSE 0 END,
    n_t_cutting = n_t_cutting + CASE WHEN NEW.trx_to = 'n_t_cutting' THEN NEW.trx_quantity ELSE 0 END,
    v_t_cutting = v_t_cutting + CASE WHEN NEW.trx_to = 'v_t_cutting' THEN NEW.trx_quantity ELSE 0 END,
    m_stopper = m_stopper + CASE WHEN NEW.trx_to = 'm_stopper' THEN NEW.trx_quantity ELSE 0 END,
    v_stopper = v_stopper + CASE WHEN NEW.trx_to = 'v_stopper' THEN NEW.trx_quantity ELSE 0 END,
    n_stopper = n_stopper + CASE WHEN NEW.trx_to = 'n_stopper' THEN NEW.trx_quantity ELSE 0 END,
    cutting = cutting + CASE WHEN NEW.trx_to = 'cutting' THEN NEW.trx_quantity ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + CASE WHEN NEW.trx_to = 'm_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + CASE WHEN NEW.trx_to = 'v_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + CASE WHEN NEW.trx_to = 'n_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + CASE WHEN NEW.trx_to = 's_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    die_casting = die_casting + CASE WHEN NEW.trx_to = 'die_casting' THEN NEW.trx_quantity ELSE 0 END,
    slider_assembly = slider_assembly + CASE WHEN NEW.trx_to = 'slider_assembly' THEN NEW.trx_quantity ELSE 0 END,
    coloring = coloring + CASE WHEN NEW.trx_to = 'coloring' THEN NEW.trx_quantity ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 C   DROP FUNCTION material.material_stock_after_material_trx_insert();
       material          postgres    false    10            [           1255    34595 *   material_stock_after_material_trx_update()    FUNCTION     C  CREATE FUNCTION material.material_stock_after_material_trx_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    stock = stock - NEW.trx_quantity + OLD.trx_quantity,
    lab_dip = lab_dip + CASE WHEN NEW.trx_to = 'lab_dip' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'lab_dip' THEN OLD.trx_quantity ELSE 0 END,
    tape_making = tape_making + CASE WHEN NEW.trx_to = 'tape_making' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'tape_making' THEN OLD.trx_quantity ELSE 0 END,
    coil_forming = coil_forming + CASE WHEN NEW.trx_to = 'coil_forming' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'coil_forming' THEN OLD.trx_quantity ELSE 0 END,
    dying_and_iron = dying_and_iron + CASE WHEN NEW.trx_to = 'dying_and_iron' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'dying_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_gapping = m_gapping + CASE WHEN NEW.trx_to = 'm_gapping' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_gapping = v_gapping + CASE WHEN NEW.trx_to = 'v_gapping' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_molding = v_teeth_molding + CASE WHEN NEW.trx_to = 'v_teeth_molding' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_molding = m_teeth_molding + CASE WHEN NEW.trx_to = 'm_teeth_molding' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + CASE WHEN NEW.trx_to = 'teeth_assembling_and_polishing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'teeth_assembling_and_polishing' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + CASE WHEN NEW.trx_to = 'm_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + CASE WHEN NEW.trx_to = 'v_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    plating_and_iron = plating_and_iron + CASE WHEN NEW.trx_to = 'plating_and_iron' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'plating_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_sealing = m_sealing + CASE WHEN NEW.trx_to = 'm_sealing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_sealing' THEN OLD.trx_quantity ELSE 0 END,
    v_sealing = v_sealing + CASE WHEN NEW.trx_to = 'v_sealing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_sealing' THEN OLD.trx_quantity ELSE 0 END,
    n_t_cutting = n_t_cutting + CASE WHEN NEW.trx_to = 'n_t_cutting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'n_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    v_t_cutting = v_t_cutting + CASE WHEN NEW.trx_to = 'v_t_cutting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_stopper = m_stopper + CASE WHEN NEW.trx_to = 'm_stopper' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_stopper' THEN OLD.trx_quantity ELSE 0 END,
    v_stopper = v_stopper + CASE WHEN NEW.trx_to = 'v_stopper' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_stopper' THEN OLD.trx_quantity ELSE 0 END,
    n_stopper = n_stopper + CASE WHEN NEW.trx_to = 'n_stopper' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'n_stopper' THEN OLD.trx_quantity ELSE 0 END,
    cutting = cutting + CASE WHEN NEW.trx_to = 'cutting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + CASE WHEN NEW.trx_to = 'm_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + CASE WHEN NEW.trx_to = 'v_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + CASE WHEN NEW.trx_to = 'n_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'n_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + CASE WHEN NEW.trx_to = 's_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 's_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    die_casting = die_casting + CASE WHEN NEW.trx_to = 'die_casting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'die_casting' THEN OLD.trx_quantity ELSE 0 END,
    slider_assembly = slider_assembly + CASE WHEN NEW.trx_to = 'slider_assembly' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'slider_assembly' THEN OLD.trx_quantity ELSE 0 END,
    coloring = coloring + CASE WHEN NEW.trx_to = 'coloring' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'coloring' THEN OLD.trx_quantity ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 C   DROP FUNCTION material.material_stock_after_material_trx_update();
       material          postgres    false    10            \           1255    34596 +   material_stock_after_material_used_delete()    FUNCTION     �  CREATE FUNCTION material.material_stock_after_material_used_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    lab_dip = lab_dip + CASE WHEN OLD.section = 'lab_dip' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    tape_making = tape_making + CASE WHEN OLD.section = 'tape_making' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coil_forming = coil_forming + CASE WHEN OLD.section = 'coil_forming' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron + CASE WHEN OLD.section = 'dying_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_gapping = m_gapping + CASE WHEN OLD.section = 'm_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_gapping = v_gapping + CASE WHEN OLD.section = 'v_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding + CASE WHEN OLD.section = 'v_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding + CASE WHEN OLD.section = 'm_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + CASE WHEN OLD.section = 'teeth_assembling_and_polishing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + CASE WHEN OLD.section = 'm_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + CASE WHEN OLD.section = 'v_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron + CASE WHEN OLD.section = 'plating_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_sealing = m_sealing + CASE WHEN OLD.section = 'm_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_sealing = v_sealing + CASE WHEN OLD.section = 'v_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting + CASE WHEN OLD.section = 'n_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting + CASE WHEN OLD.section = 'v_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_stopper = m_stopper + CASE WHEN OLD.section = 'm_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_stopper = v_stopper + CASE WHEN OLD.section = 'v_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_stopper = n_stopper + CASE WHEN OLD.section = 'n_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    cutting = cutting + CASE WHEN OLD.section = 'cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + CASE WHEN OLD.section = 'm_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + CASE WHEN OLD.section = 'v_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + CASE WHEN OLD.section = 'n_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + CASE WHEN OLD.section = 's_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    die_casting = die_casting + CASE WHEN OLD.section = 'die_casting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    slider_assembly = slider_assembly + CASE WHEN OLD.section = 'slider_assembly' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coloring = coloring + CASE WHEN OLD.section = 'coloring' THEN OLD.used_quantity + OLD.wastage ELSE 0 END
    WHERE material_uuid = OLD.material_uuid;
    RETURN OLD;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_used_delete();
       material          postgres    false    10            ]           1255    34597 +   material_stock_after_material_used_insert()    FUNCTION     �  CREATE FUNCTION material.material_stock_after_material_used_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    lab_dip = lab_dip - CASE WHEN NEW.section = 'lab_dip' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    tape_making = tape_making - CASE WHEN NEW.section = 'tape_making' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coil_forming = coil_forming - CASE WHEN NEW.section = 'coil_forming' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron - CASE WHEN NEW.section = 'dying_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_gapping = m_gapping - CASE WHEN NEW.section = 'm_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_gapping = v_gapping - CASE WHEN NEW.section = 'v_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding - CASE WHEN NEW.section = 'v_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding - CASE WHEN NEW.section = 'm_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing - CASE WHEN NEW.section = 'teeth_assembling_and_polishing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning - CASE WHEN NEW.section = 'm_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning - CASE WHEN NEW.section = 'v_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron - CASE WHEN NEW.section = 'plating_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_sealing = m_sealing - CASE WHEN NEW.section = 'm_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_sealing = v_sealing - CASE WHEN NEW.section = 'v_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting - CASE WHEN NEW.section = 'n_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting - CASE WHEN NEW.section = 'v_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_stopper = m_stopper - CASE WHEN NEW.section = 'm_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_stopper = v_stopper - CASE WHEN NEW.section = 'v_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_stopper = n_stopper - CASE WHEN NEW.section = 'n_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    cutting = cutting - CASE WHEN NEW.section = 'cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing - CASE WHEN NEW.section = 'm_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing - CASE WHEN NEW.section = 'v_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing - CASE WHEN NEW.section = 'n_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing - CASE WHEN NEW.section = 's_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    die_casting = die_casting - CASE WHEN NEW.section = 'die_casting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    slider_assembly = slider_assembly - CASE WHEN NEW.section = 'slider_assembly' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coloring = coloring - CASE WHEN NEW.section = 'coloring' THEN NEW.used_quantity + NEW.wastage ELSE 0 END
   
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_used_insert();
       material          postgres    false    10            ^           1255    34598 +   material_stock_after_material_used_update()    FUNCTION     L  CREATE FUNCTION material.material_stock_after_material_used_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    lab_dip = lab_dip + 
    CASE WHEN NEW.section = 'lab_dip' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    tape_making = tape_making + 
    CASE WHEN OLD.section = 'tape_making' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coil_forming = coil_forming + 
    CASE WHEN OLD.section = 'coil_forming' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron + 
    CASE WHEN OLD.section = 'dying_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_gapping = m_gapping + 
    CASE WHEN OLD.section = 'm_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_gapping = v_gapping + 
    CASE WHEN OLD.section = 'v_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding + 
    CASE WHEN OLD.section = 'v_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding + 
    CASE WHEN OLD.section = 'm_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + 
    CASE WHEN OLD.section = 'teeth_assembling_and_polishing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + 
    CASE WHEN OLD.section = 'm_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + 
    CASE WHEN OLD.section = 'v_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron + 
    CASE WHEN OLD.section = 'plating_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_sealing = m_sealing + 
    CASE WHEN OLD.section = 'm_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_sealing = v_sealing + 
    CASE WHEN OLD.section = 'v_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting + 
    CASE WHEN OLD.section = 'n_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting + 
    CASE WHEN OLD.section = 'v_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_stopper = m_stopper + 
    CASE WHEN OLD.section = 'm_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_stopper = v_stopper + 
    CASE WHEN OLD.section = 'v_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_stopper = n_stopper + 
    CASE WHEN OLD.section = 'n_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    cutting = cutting + 
    CASE WHEN OLD.section = 'cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + 
    CASE WHEN OLD.section = 'm_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + 
    CASE WHEN OLD.section = 'v_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + 
    CASE WHEN OLD.section = 'n_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + 
    CASE WHEN OLD.section = 's_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    die_casting = die_casting + 
    CASE WHEN OLD.section = 'die_casting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    slider_assembly = slider_assembly + 
    CASE WHEN OLD.section = 'slider_assembly' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coloring = coloring + 
    CASE WHEN OLD.section = 'coloring' THEN OLD.used_quantity + OLD.wastage ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;

    UPDATE material.stock
    SET
    lab_dip = lab_dip -
    CASE WHEN NEW.section = 'lab_dip' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    tape_making = tape_making -
    CASE WHEN NEW.section = 'tape_making' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coil_forming = coil_forming -
    CASE WHEN NEW.section = 'coil_forming' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron -
    CASE WHEN NEW.section = 'dying_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_gapping = m_gapping -
    CASE WHEN NEW.section = 'm_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_gapping = v_gapping -
    CASE WHEN NEW.section = 'v_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding -
    CASE WHEN NEW.section = 'v_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding -
    CASE WHEN NEW.section = 'm_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing -
    CASE WHEN NEW.section = 'teeth_assembling_and_polishing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning -
    CASE WHEN NEW.section = 'm_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning -
    CASE WHEN NEW.section = 'v_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron -
    CASE WHEN NEW.section = 'plating_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_sealing = m_sealing -
    CASE WHEN NEW.section = 'm_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_sealing = v_sealing -
    CASE WHEN NEW.section = 'v_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting -
    CASE WHEN NEW.section = 'n_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting -
    CASE WHEN NEW.section = 'v_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_stopper = m_stopper -
    CASE WHEN NEW.section = 'm_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_stopper = v_stopper -
    CASE WHEN NEW.section = 'v_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_stopper = n_stopper -
    CASE WHEN NEW.section = 'n_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    cutting = cutting -
    CASE WHEN NEW.section = 'cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing -
    CASE WHEN NEW.section = 'm_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing -
    CASE WHEN NEW.section = 'v_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing -
    CASE WHEN NEW.section = 'n_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing -
    CASE WHEN NEW.section = 's_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    die_casting = die_casting -
    CASE WHEN NEW.section = 'die_casting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    slider_assembly = slider_assembly -
    CASE WHEN NEW.section = 'slider_assembly' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coloring = coloring -
    CASE WHEN NEW.section = 'coloring' THEN NEW.used_quantity + NEW.wastage ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_used_update();
       material          postgres    false    10            _           1255    34599 ,   material_stock_after_purchase_entry_delete()    FUNCTION       CREATE FUNCTION material.material_stock_after_purchase_entry_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
        SET 
            stock = stock - OLD.quantity
    WHERE material_uuid = OLD.material_uuid;
    RETURN OLD;
END;

$$;
 E   DROP FUNCTION material.material_stock_after_purchase_entry_delete();
       material          postgres    false    10            `           1255    34600 ,   material_stock_after_purchase_entry_insert()    FUNCTION       CREATE FUNCTION material.material_stock_after_purchase_entry_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
        SET 
            stock = stock + NEW.quantity
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 E   DROP FUNCTION material.material_stock_after_purchase_entry_insert();
       material          postgres    false    10            a           1255    34601 ,   material_stock_after_purchase_entry_update()    FUNCTION       CREATE FUNCTION material.material_stock_after_purchase_entry_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    IF NEW.material_uuid <> OLD.material_uuid THEN
        -- Deduct the old quantity from the old item's stock
        UPDATE material.stock
        SET stock = stock - OLD.quantity
        WHERE material_uuid = OLD.material_uuid;

        -- Add the new quantity to the new item's stock
        UPDATE material.stock
        SET stock = stock + NEW.quantity
        WHERE material_uuid = NEW.material_uuid;
    ELSE
        -- If the item has not changed, update the stock with the difference
        UPDATE material.stock
        SET stock = stock + NEW.quantity - OLD.quantity
        WHERE material_uuid = NEW.material_uuid;
    END IF;
    RETURN NEW;
END;

$$;
 E   DROP FUNCTION material.material_stock_after_purchase_entry_update();
       material          postgres    false    10            b           1255    34602 .   material_stock_sfg_after_stock_to_sfg_delete()    FUNCTION     4  CREATE FUNCTION material.material_stock_sfg_after_stock_to_sfg_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update material.stock table
    UPDATE material.stock 
    SET
        stock = stock + OLD.trx_quantity
    WHERE stock.material_uuid = OLD.material_uuid;

    --Update zipper.sfg table
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod 
            - CASE WHEN OLD.trx_to = 'dying_and_iron_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_stock = teeth_molding_stock 
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_prod = teeth_molding_prod 
            - CASE WHEN OLD.trx_to = 'teeth_molding_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod
            - CASE WHEN OLD.trx_to = 'teeth_coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        finishing_stock = finishing_stock
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN OLD.trx_quantity ELSE 0 END,
        finishing_prod = finishing_prod
            - CASE WHEN OLD.trx_to = 'finishing_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_prod = coloring_prod
            - CASE WHEN OLD.trx_to = 'coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        warehouse = warehouse
            - CASE WHEN OLD.trx_to = 'warehouse' THEN OLD.trx_quantity ELSE 0 END,
        delivered = delivered
            - CASE WHEN OLD.trx_to = 'delivered' THEN OLD.trx_quantity ELSE 0 END,
        pi = pi 
            - CASE WHEN OLD.trx_to = 'pi' THEN OLD.trx_quantity ELSE 0 END
    WHERE order_entry_uuid = OLD.order_entry_uuid;

    RETURN OLD;
END;
$$;
 G   DROP FUNCTION material.material_stock_sfg_after_stock_to_sfg_delete();
       material          postgres    false    10            d           1255    34603 .   material_stock_sfg_after_stock_to_sfg_insert()    FUNCTION     =  CREATE FUNCTION material.material_stock_sfg_after_stock_to_sfg_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update material.stock table
    UPDATE material.stock 
    SET
        stock = stock - NEW.trx_quantity
    WHERE stock.material_uuid = NEW.material_uuid;

    --Update zipper.sfg table
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod 
            + CASE WHEN NEW.trx_to = 'dying_and_iron_prod' THEN NEW.trx_quantity ELSE 0 END,
        teeth_molding_stock = teeth_molding_stock 
            + CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN NEW.trx_quantity ELSE 0 END,
        teeth_molding_prod = teeth_molding_prod 
            + CASE WHEN NEW.trx_to = 'teeth_molding_prod' THEN NEW.trx_quantity ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock
            + CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN NEW.trx_quantity ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod
            + CASE WHEN NEW.trx_to = 'teeth_coloring_prod' THEN NEW.trx_quantity ELSE 0 END,
        finishing_stock = finishing_stock
            + CASE WHEN NEW.trx_to = 'finishing_stock' THEN NEW.trx_quantity ELSE 0 END,
        finishing_prod = finishing_prod
            + CASE WHEN NEW.trx_to = 'finishing_prod' THEN NEW.trx_quantity ELSE 0 END,
        coloring_prod = coloring_prod
            + CASE WHEN NEW.trx_to = 'coloring_prod' THEN NEW.trx_quantity ELSE 0 END,
        warehouse = warehouse
            + CASE WHEN NEW.trx_to = 'warehouse' THEN NEW.trx_quantity ELSE 0 END,
        delivered = delivered
            + CASE WHEN NEW.trx_to = 'delivered' THEN NEW.trx_quantity ELSE 0 END,
        pi = pi 
            + CASE WHEN NEW.trx_to = 'pi' THEN NEW.trx_quantity ELSE 0 END
        
    WHERE order_entry_uuid = NEW.order_entry_uuid;
    RETURN NEW;

END;
$$;
 G   DROP FUNCTION material.material_stock_sfg_after_stock_to_sfg_insert();
       material          postgres    false    10            e           1255    34604 .   material_stock_sfg_after_stock_to_sfg_update()    FUNCTION       CREATE FUNCTION material.material_stock_sfg_after_stock_to_sfg_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update material.stock table
    UPDATE material.stock 
    SET
        stock = stock - NEW.trx_quantity + OLD.trx_quantity
    WHERE stock.material_uuid = NEW.material_uuid;

    --Update zipper.sfg table
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod 
            + CASE WHEN NEW.trx_to = 'dying_and_iron_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'dying_and_iron_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_stock = teeth_molding_stock 
            + CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_prod = teeth_molding_prod 
            + CASE WHEN NEW.trx_to = 'teeth_molding_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_molding_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock
            + CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod
            + CASE WHEN NEW.trx_to = 'teeth_coloring_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        finishing_stock = finishing_stock
            + CASE WHEN NEW.trx_to = 'finishing_stock' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN OLD.trx_quantity ELSE 0 END,
        finishing_prod = finishing_prod
            + CASE WHEN NEW.trx_to = 'finishing_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'finishing_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_prod = coloring_prod
            + CASE WHEN NEW.trx_to = 'coloring_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        warehouse = warehouse
            + CASE WHEN NEW.trx_to = 'warehouse' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'warehouse' THEN OLD.trx_quantity ELSE 0 END,
        delivered = delivered
            + CASE WHEN NEW.trx_to = 'delivered' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'delivered' THEN OLD.trx_quantity ELSE 0 END,
        pi = pi
            + CASE WHEN NEW.trx_to = 'pi' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'pi' THEN OLD.trx_quantity ELSE 0 END
    WHERE order_entry_uuid = NEW.order_entry_uuid;

    RETURN NEW;

END;
$$;
 G   DROP FUNCTION material.material_stock_sfg_after_stock_to_sfg_update();
       material          postgres    false    10            f           1255    34605 >   thread_batch_entry_after_batch_entry_production_delete_funct()    FUNCTION     �  CREATE FUNCTION public.thread_batch_entry_after_batch_entry_production_delete_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE thread.batch_entry
    SET
        coning_production_quantity = coning_production_quantity - OLD.production_quantity,
        coning_carton_quantity = coning_carton_quantity - OLD.coning_carton_quantity
    WHERE uuid = OLD.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        production_quantity = production_quantity - OLD.production_quantity
        -- production_quantity_in_kg = production_quantity_in_kg - OLD.production_quantity_in_kg

    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = OLD.batch_entry_uuid);

    RETURN OLD;
END;

$$;
 U   DROP FUNCTION public.thread_batch_entry_after_batch_entry_production_delete_funct();
       public          postgres    false    15            g           1255    34606 >   thread_batch_entry_after_batch_entry_production_insert_funct()    FUNCTION     �  CREATE FUNCTION public.thread_batch_entry_after_batch_entry_production_insert_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        coning_production_quantity = coning_production_quantity + NEW.production_quantity,
        coning_carton_quantity = coning_carton_quantity + NEW.coning_carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        production_quantity = production_quantity + NEW.production_quantity
        -- production_quantity_in_kg = production_quantity_in_kg + NEW.production_quantity_in_kg

    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);

    RETURN NEW;
END;

$$;
 U   DROP FUNCTION public.thread_batch_entry_after_batch_entry_production_insert_funct();
       public          postgres    false    15            h           1255    34607 >   thread_batch_entry_after_batch_entry_production_update_funct()    FUNCTION     P  CREATE FUNCTION public.thread_batch_entry_after_batch_entry_production_update_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        coning_production_quantity = coning_production_quantity - OLD.production_quantity + NEW.production_quantity,
        coning_carton_quantity = coning_carton_quantity - OLD.coning_carton_quantity + NEW.coning_carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        production_quantity = production_quantity - OLD.production_quantity + NEW.production_quantity
        -- production_quantity_in_kg = production_quantity_in_kg - OLD.production_quantity_in_kg + NEW.production_quantity_in_kg

    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);

    RETURN NEW;
END;

$$;
 U   DROP FUNCTION public.thread_batch_entry_after_batch_entry_production_update_funct();
       public          postgres    false    15            i           1255    34608 A   thread_batch_entry_and_order_entry_after_batch_entry_trx_delete()    FUNCTION        CREATE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        transfer_quantity = transfer_quantity - OLD.quantity,
        coning_production_quantity = coning_production_quantity + OLD.quantity,
        transfer_carton_quantity = transfer_carton_quantity - OLD.carton_quantity,
        coning_carton_quantity = coning_carton_quantity + OLD.carton_quantity
    WHERE uuid = OLD.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        warehouse = warehouse - OLD.quantity,
        carton_quantity = carton_quantity - OLD.carton_quantity
    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = OLD.batch_entry_uuid);
    RETURN OLD;
END;

$$;
 X   DROP FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_delete();
       public          postgres    false    15            j           1255    34609 @   thread_batch_entry_and_order_entry_after_batch_entry_trx_funct()    FUNCTION       CREATE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        transfer_quantity = transfer_quantity + NEW.quantity,
        coning_production_quantity = coning_production_quantity - NEW.quantity,
        transfer_carton_quantity = transfer_carton_quantity + NEW.carton_quantity,
        coning_carton_quantity = coning_carton_quantity - NEW.carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        warehouse = warehouse + NEW.quantity,
        carton_quantity = carton_quantity + NEW.carton_quantity
    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);
    RETURN NEW;
END;

$$;
 W   DROP FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_funct();
       public          postgres    false    15            k           1255    34610 A   thread_batch_entry_and_order_entry_after_batch_entry_trx_update()    FUNCTION     �  CREATE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE thread.batch_entry
    SET
        transfer_quantity = transfer_quantity - OLD.quantity + NEW.quantity,
        coning_production_quantity = coning_production_quantity + OLD.quantity - NEW.quantity,
        transfer_carton_quantity = transfer_carton_quantity - OLD.carton_quantity + NEW.carton_quantity,
        coning_carton_quantity = coning_carton_quantity + OLD.carton_quantity - NEW.carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        warehouse = warehouse - OLD.quantity + NEW.quantity,
        carton_quantity = carton_quantity - OLD.carton_quantity + NEW.carton_quantity
    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);
    RETURN NEW;
END;

$$;
 X   DROP FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_update();
       public          postgres    false    15            @           1255    34611 2   zipper_batch_entry_after_batch_production_delete()    FUNCTION     F  CREATE FUNCTION public.zipper_batch_entry_after_batch_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.batch_entry
    SET
        production_quantity_in_kg = production_quantity_in_kg - OLD.production_quantity_in_kg
    WHERE
        uuid = OLD.batch_entry_uuid;
    
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod - OLD.production_quantity_in_kg
        FROM zipper.batch_entry
    WHERE
         zipper.sfg.uuid = batch_entry.sfg_uuid AND batch_entry.uuid = OLD.batch_entry_uuid;
    RETURN OLD;
END;

$$;
 I   DROP FUNCTION public.zipper_batch_entry_after_batch_production_delete();
       public          postgres    false    15            A           1255    34612 2   zipper_batch_entry_after_batch_production_insert()    FUNCTION     7  CREATE FUNCTION public.zipper_batch_entry_after_batch_production_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.batch_entry
    SET
        production_quantity_in_kg = production_quantity_in_kg + NEW.production_quantity_in_kg
    WHERE
        uuid = NEW.batch_entry_uuid;

 UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg
    FROM zipper.batch_entry
    WHERE
        zipper.sfg.uuid = batch_entry.sfg_uuid AND batch_entry.uuid = NEW.batch_entry_uuid;
RETURN NEW;

END;

$$;
 I   DROP FUNCTION public.zipper_batch_entry_after_batch_production_insert();
       public          postgres    false    15            c           1255    34613 2   zipper_batch_entry_after_batch_production_update()    FUNCTION     �  CREATE FUNCTION public.zipper_batch_entry_after_batch_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.batch_entry
    SET
        production_quantity_in_kg = production_quantity_in_kg + NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
    WHERE
        uuid = NEW.batch_entry_uuid;

  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
        FROM zipper.batch_entry
    WHERE
         zipper.sfg.uuid = batch_entry.sfg_uuid AND batch_entry.uuid = NEW.batch_entry_uuid;
    RETURN NEW;

RETURN NEW;
      
END;

$$;
 I   DROP FUNCTION public.zipper_batch_entry_after_batch_production_update();
       public          postgres    false    15            l           1255    34614 %   zipper_sfg_after_batch_entry_delete()    FUNCTION     #  CREATE FUNCTION public.zipper_sfg_after_batch_entry_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod - OLD.production_quantity_in_kg
    WHERE
        uuid = OLD.sfg_uuid;

    RETURN OLD;
END;

$$;
 <   DROP FUNCTION public.zipper_sfg_after_batch_entry_delete();
       public          postgres    false    15            ;           1255    34615 %   zipper_sfg_after_batch_entry_insert()    FUNCTION     %  CREATE FUNCTION public.zipper_sfg_after_batch_entry_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg
    WHERE
        uuid = NEW.sfg_uuid;
    
    RETURN NEW;
END;
$$;
 <   DROP FUNCTION public.zipper_sfg_after_batch_entry_insert();
       public          postgres    false    15            <           1255    34616 %   zipper_sfg_after_batch_entry_update()    FUNCTION     E  CREATE FUNCTION public.zipper_sfg_after_batch_entry_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
    WHERE
        uuid = NEW.sfg_uuid;

    RETURN NEW;	
END;



$$;
 <   DROP FUNCTION public.zipper_sfg_after_batch_entry_update();
       public          postgres    false    15            m           1255    34617 A   assembly_stock_after_die_casting_to_assembly_stock_delete_funct()    FUNCTION       CREATE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_delete_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.assembly_stock
    UPDATE slider.assembly_stock
    SET
        quantity = quantity - OLD.production_quantity
    WHERE uuid = OLD.assembly_stock_uuid;

    -- die casting body
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_body_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    -- die casting cap
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_cap_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    -- die casting puller
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_puller_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    -- die casting link
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity + OLD.wastage ELSE 0 END
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_link_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    RETURN OLD;
END;
$$;
 X   DROP FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_delete_funct();
       slider          postgres    false    12            n           1255    34618 A   assembly_stock_after_die_casting_to_assembly_stock_insert_funct()    FUNCTION       CREATE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_insert_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.assembly_stock
    UPDATE slider.assembly_stock
    SET
        quantity = quantity + NEW.production_quantity
    WHERE uuid = NEW.assembly_stock_uuid;

    -- die casting body 
    UPDATE slider.die_casting 
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_body_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting cap
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_cap_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting puller
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_puller_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting link
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity - NEW.wastage ELSE 0 END
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_link_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_insert_funct();
       slider          postgres    false    12            o           1255    34619 A   assembly_stock_after_die_casting_to_assembly_stock_update_funct()    FUNCTION     
  CREATE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_update_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.assembly_stock
    UPDATE slider.assembly_stock
    SET
        quantity = quantity 
            + NEW.production_quantity
            - OLD.production_quantity
    WHERE uuid = NEW.assembly_stock_uuid;

    -- die casting body
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_body_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting cap
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_cap_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting puller
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_puller_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting link
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity + NEW.wastage ELSE 0 END + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity + OLD.wastage ELSE 0 END
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_link_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_update_funct();
       slider          postgres    false    12            p           1255    34620 8   slider_die_casting_after_die_casting_production_delete()    FUNCTION     |  CREATE FUNCTION slider.slider_die_casting_after_die_casting_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity = quantity - (OLD.cavity_goods * OLD.push),
        weight = weight - OLD.weight
        WHERE uuid = OLD.die_casting_uuid;
    RETURN OLD;
    END;
$$;
 O   DROP FUNCTION slider.slider_die_casting_after_die_casting_production_delete();
       slider          postgres    false    12            q           1255    34621 8   slider_die_casting_after_die_casting_production_insert()    FUNCTION     }  CREATE FUNCTION slider.slider_die_casting_after_die_casting_production_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN 
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity = quantity + (NEW.cavity_goods * NEW.push),
        weight = weight + NEW.weight
        WHERE uuid = NEW.die_casting_uuid;
    RETURN NEW;
    END;
$$;
 O   DROP FUNCTION slider.slider_die_casting_after_die_casting_production_insert();
       slider          postgres    false    12            r           1255    34622 8   slider_die_casting_after_die_casting_production_update()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_die_casting_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

--update slider.die_casting table

    UPDATE slider.die_casting
        SET 
        quantity = quantity + (NEW.cavity_goods * NEW.push) - (OLD.cavity_goods * OLD.push),
        weight = weight + NEW.weight - OLD.weight
        WHERE uuid = NEW.die_casting_uuid;
    RETURN NEW;
    END;

$$;
 O   DROP FUNCTION slider.slider_die_casting_after_die_casting_production_update();
       slider          postgres    false    12            s           1255    34623 3   slider_die_casting_after_trx_against_stock_delete()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_trx_against_stock_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity_in_sa = quantity_in_sa - OLD.quantity,
        quantity = quantity + OLD.quantity,
        weight = weight + OLD.weight
        WHERE uuid = OLD.die_casting_uuid;
    RETURN OLD;
    END;
$$;
 J   DROP FUNCTION slider.slider_die_casting_after_trx_against_stock_delete();
       slider          postgres    false    12            t           1255    34624 3   slider_die_casting_after_trx_against_stock_insert()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_trx_against_stock_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity_in_sa = quantity_in_sa + NEW.quantity,
        quantity = quantity - NEW.quantity,
        weight = weight - NEW.weight
        WHERE uuid = NEW.die_casting_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION slider.slider_die_casting_after_trx_against_stock_insert();
       slider          postgres    false    12            u           1255    34625 3   slider_die_casting_after_trx_against_stock_update()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_trx_against_stock_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 

        quantity_in_sa = quantity_in_sa + NEW.quantity - OLD.quantity,
        quantity = quantity - NEW.quantity + OLD.quantity,
        weight = weight - NEW.weight + OLD.weight
        WHERE uuid = NEW.die_casting_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION slider.slider_die_casting_after_trx_against_stock_update();
       slider          postgres    false    12            =           1255    34626 0   slider_stock_after_coloring_transaction_delete()    FUNCTION       CREATE FUNCTION slider.slider_stock_after_coloring_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = CASE WHEN uuid = OLD.stock_uuid THEN sa_prod + OLD.trx_quantity ELSE sa_prod END,
        coloring_stock = CASE WHEN order_info_uuid = OLD.order_info_uuid THEN coloring_stock - OLD.trx_quantity ELSE coloring_stock END

    WHERE uuid = OLD.stock_uuid OR order_info_uuid = OLD.order_info_uuid;

    RETURN OLD;
END;

$$;
 G   DROP FUNCTION slider.slider_stock_after_coloring_transaction_delete();
       slider          postgres    false    12            >           1255    34627 0   slider_stock_after_coloring_transaction_insert()    FUNCTION       CREATE FUNCTION slider.slider_stock_after_coloring_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = CASE WHEN uuid = NEW.stock_uuid THEN sa_prod - NEW.trx_quantity ELSE sa_prod END,
        coloring_stock = CASE WHEN order_info_uuid = NEW.order_info_uuid THEN coloring_stock + NEW.trx_quantity ELSE coloring_stock END

    WHERE uuid = NEW.stock_uuid OR order_info_uuid = NEW.order_info_uuid;

    RETURN NEW;
END;
$$;
 G   DROP FUNCTION slider.slider_stock_after_coloring_transaction_insert();
       slider          postgres    false    12            v           1255    34628 0   slider_stock_after_coloring_transaction_update()    FUNCTION     7  CREATE FUNCTION slider.slider_stock_after_coloring_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = CASE WHEN uuid = NEW.stock_uuid THEN sa_prod - NEW.trx_quantity + OLD.trx_quantity ELSE sa_prod END,
        coloring_stock = CASE WHEN order_info_uuid = NEW.order_info_uuid THEN coloring_stock + NEW.trx_quantity - OLD.trx_quantity ELSE coloring_stock END

    WHERE uuid = NEW.stock_uuid OR order_info_uuid = NEW.order_info_uuid;

    RETURN NEW;
END;

$$;
 G   DROP FUNCTION slider.slider_stock_after_coloring_transaction_update();
       slider          postgres    false    12            w           1255    34629 3   slider_stock_after_die_casting_transaction_delete()    FUNCTION     �  CREATE FUNCTION slider.slider_stock_after_die_casting_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 UPDATE slider.die_casting
    SET
        quantity = quantity + OLD.trx_quantity,
        weight = weight + OLD.weight
    WHERE uuid = OLD.die_casting_uuid;

    --update slider.stock table
    UPDATE slider.stock
    SET
        body_quantity = body_quantity 
            - CASE WHEN dc.type = 'body' THEN OLD.trx_quantity ELSE 0 END,
        puller_quantity = puller_quantity 
            - CASE WHEN dc.type = 'puller' THEN OLD.trx_quantity ELSE 0 END,
        cap_quantity = cap_quantity 
            - CASE WHEN dc.type = 'cap' THEN OLD.trx_quantity ELSE 0 END,
        link_quantity = link_quantity 
            - CASE WHEN dc.type = 'link' THEN OLD.trx_quantity ELSE 0 END,
        h_bottom_quantity = h_bottom_quantity 
            - CASE WHEN dc.type = 'h_bottom' THEN OLD.trx_quantity ELSE 0 END,
        u_top_quantity = u_top_quantity 
            - CASE WHEN dc.type = 'u_top' THEN OLD.trx_quantity ELSE 0 END,
        box_pin_quantity = box_pin_quantity 
            - CASE WHEN dc.type = 'box_pin' THEN OLD.trx_quantity ELSE 0 END,
        two_way_pin_quantity = two_way_pin_quantity 
            - CASE WHEN dc.type = 'two_way_pin' THEN OLD.trx_quantity ELSE 0 END
    FROM slider.die_casting dc
    WHERE stock.uuid = NEW.stock_uuid AND dc.uuid = NEW.die_casting_uuid;


RETURN OLD;
END;

$$;
 J   DROP FUNCTION slider.slider_stock_after_die_casting_transaction_delete();
       slider          postgres    false    12            x           1255    34630 3   slider_stock_after_die_casting_transaction_insert()    FUNCTION     �  CREATE FUNCTION slider.slider_stock_after_die_casting_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.die_casting
    SET
        quantity = quantity - NEW.trx_quantity,
        weight = weight - NEW.weight
    WHERE uuid = NEW.die_casting_uuid;

    UPDATE slider.stock
    SET
        body_quantity = body_quantity 
            + CASE WHEN dc.type = 'body' THEN NEW.trx_quantity ELSE 0 END,
        puller_quantity = puller_quantity 
            + CASE WHEN dc.type = 'puller' THEN NEW.trx_quantity ELSE 0 END,
        cap_quantity = cap_quantity 
            + CASE WHEN dc.type = 'cap' THEN NEW.trx_quantity ELSE 0 END,
        link_quantity = link_quantity 
            + CASE WHEN dc.type = 'link' THEN NEW.trx_quantity ELSE 0 END,
        h_bottom_quantity = h_bottom_quantity 
            + CASE WHEN dc.type = 'h_bottom' THEN NEW.trx_quantity ELSE 0 END,
        u_top_quantity = u_top_quantity 
            + CASE WHEN dc.type = 'u_top' THEN NEW.trx_quantity ELSE 0 END,
        box_pin_quantity = box_pin_quantity 
            + CASE WHEN dc.type = 'box_pin' THEN NEW.trx_quantity ELSE 0 END,
        two_way_pin_quantity = two_way_pin_quantity 
            + CASE WHEN dc.type = 'two_way_pin' THEN NEW.trx_quantity ELSE 0 END
    FROM slider.die_casting dc
    WHERE stock.uuid = NEW.stock_uuid AND dc.uuid = NEW.die_casting_uuid;

RETURN NEW;
END;
$$;
 J   DROP FUNCTION slider.slider_stock_after_die_casting_transaction_insert();
       slider          postgres    false    12            y           1255    34631 3   slider_stock_after_die_casting_transaction_update()    FUNCTION     *  CREATE FUNCTION slider.slider_stock_after_die_casting_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.die_casting
    SET
        quantity = quantity - NEW.trx_quantity + OLD.trx_quantity,
        weight = weight - NEW.weight + OLD.weight
    WHERE uuid = NEW.die_casting_uuid;

    UPDATE slider.stock
    SET
        body_quantity = body_quantity 
            + CASE WHEN dc.type = 'body' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'body' THEN OLD.trx_quantity ELSE 0 END,
        puller_quantity = puller_quantity 
            + CASE WHEN dc.type = 'puller' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'puller' THEN OLD.trx_quantity ELSE 0 END,
        cap_quantity = cap_quantity 
            + CASE WHEN dc.type = 'cap' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'cap' THEN OLD.trx_quantity ELSE 0 END,
        link_quantity = link_quantity 
            + CASE WHEN dc.type = 'link' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'link' THEN OLD.trx_quantity ELSE 0 END,
        h_bottom_quantity = h_bottom_quantity 
            + CASE WHEN dc.type = 'h_bottom' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'h_bottom' THEN OLD.trx_quantity ELSE 0 END,
        u_top_quantity = u_top_quantity 
            + CASE WHEN dc.type = 'u_top' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'u_top' THEN OLD.trx_quantity ELSE 0 END,
        box_pin_quantity = box_pin_quantity 
            + CASE WHEN dc.type = 'box_pin' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'box_pin' THEN OLD.trx_quantity ELSE 0 END,
        two_way_pin_quantity = two_way_pin_quantity 
            + CASE WHEN dc.type = 'two_way_pin' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'two_way_pin' THEN OLD.trx_quantity ELSE 0 END
    FROM slider.die_casting dc
    WHERE stock.uuid = NEW.stock_uuid AND dc.uuid = NEW.die_casting_uuid;

RETURN NEW;
END;

$$;
 J   DROP FUNCTION slider.slider_stock_after_die_casting_transaction_update();
       slider          postgres    false    12            z           1255    34632 -   slider_stock_after_slider_production_delete()    FUNCTION     �  CREATE FUNCTION slider.slider_stock_after_slider_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   
    -- Update slider.stock table for 'sa_prod' section
    IF OLD.section = 'sa_prod' THEN
        UPDATE slider.stock
        SET
            sa_prod = sa_prod - OLD.production_quantity,
            body_quantity =  body_quantity + OLD.production_quantity,
            cap_quantity = cap_quantity + OLD.production_quantity,
            puller_quantity = puller_quantity + OLD.production_quantity,
            link_quantity = link_quantity + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity ELSE 0 END
        FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = OLD.stock_uuid;
    END IF;

    -- Update slider.stock table for 'coloring' section
    IF OLD.section = 'coloring' THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock + OLD.production_quantity,
            link_quantity = link_quantity + OLD.production_quantity,
            box_pin_quantity = box_pin_quantity + CASE WHEN lower(vodf.end_type_name) = 'open end' THEN OLD.production_quantity ELSE 0 END,
            h_bottom_quantity = h_bottom_quantity + CASE WHEN lower(vodf.end_type_name) = 'close end' THEN OLD.production_quantity ELSE 0 END,
            u_top_quantity = u_top_quantity + (2 * OLD.production_quantity),
            coloring_prod = coloring_prod - OLD.production_quantity
        FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = OLD.stock_uuid;
    END IF;

    RETURN OLD;
END;
$$;
 D   DROP FUNCTION slider.slider_stock_after_slider_production_delete();
       slider          postgres    false    12            {           1255    34633 -   slider_stock_after_slider_production_insert()    FUNCTION     o  CREATE FUNCTION slider.slider_stock_after_slider_production_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table for 'sa_prod' section
   
      IF NEW.section = 'sa_prod' THEN
            UPDATE slider.stock
            SET
                sa_prod = sa_prod + NEW.production_quantity,
                body_quantity =  body_quantity - NEW.production_quantity,
                cap_quantity = cap_quantity - NEW.production_quantity,
                puller_quantity = puller_quantity - NEW.production_quantity,
                link_quantity = link_quantity - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity ELSE 0 END
            WHERE stock.uuid = NEW.stock_uuid;
    END IF;

-- Update slider.stock table for 'coloring' section

    IF NEW.section = 'coloring' THEN

        UPDATE slider.stock
            SET
                coloring_stock = coloring_stock - NEW.production_quantity,
                link_quantity = link_quantity - NEW.production_quantity,
                box_pin_quantity = box_pin_quantity - CASE WHEN lower(vodf.end_type_name) = 'open end' THEN NEW.production_quantity ELSE 0 END,
                h_bottom_quantity = h_bottom_quantity - CASE WHEN lower(vodf.end_type_name) = 'close end' THEN NEW.production_quantity ELSE 0 END,
                u_top_quantity = u_top_quantity - (2 * NEW.production_quantity),
                coloring_prod = coloring_prod + NEW.production_quantity
            FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = NEW.stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 D   DROP FUNCTION slider.slider_stock_after_slider_production_insert();
       slider          postgres    false    12            |           1255    34634 -   slider_stock_after_slider_production_update()    FUNCTION     {  CREATE FUNCTION slider.slider_stock_after_slider_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table for 'sa_prod' section
    IF NEW.section = 'sa_prod' THEN
        UPDATE slider.stock
        SET
            sa_prod = sa_prod + NEW.production_quantity - OLD.production_quantity,
            body_quantity =  body_quantity - NEW.production_quantity + OLD.production_quantity,
            cap_quantity = cap_quantity - NEW.production_quantity + OLD.production_quantity,
            puller_quantity = puller_quantity - NEW.production_quantity + OLD.production_quantity,
            link_quantity = link_quantity - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity ELSE 0 END + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity ELSE 0 END
        WHERE stock.uuid = NEW.stock_uuid;
    END IF;

    -- Update slider.stock table for 'coloring' section
    IF NEW.section = 'coloring' THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock - NEW.production_quantity + OLD.production_quantity,
            link_quantity = link_quantity - NEW.production_quantity + OLD.production_quantity,
            box_pin_quantity = box_pin_quantity - CASE WHEN lower(vodf.end_type_name) = 'open end' THEN NEW.production_quantity - OLD.production_quantity ELSE 0 END,
            h_bottom_quantity = h_bottom_quantity - CASE WHEN lower(vodf.end_type_name) = 'close end' THEN NEW.production_quantity - OLD.production_quantity ELSE 0 END,
            u_top_quantity = u_top_quantity - (2 * (NEW.production_quantity - OLD.production_quantity)),
            coloring_prod = coloring_prod + NEW.production_quantity - OLD.production_quantity
            FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = NEW.stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 D   DROP FUNCTION slider.slider_stock_after_slider_production_update();
       slider          postgres    false    12            }           1255    34635 '   slider_stock_after_transaction_delete()    FUNCTION     {  CREATE FUNCTION slider.slider_stock_after_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = sa_prod + CASE WHEN OLD.from_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_stock = coloring_stock + CASE WHEN OLD.from_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
    WHERE uuid = OLD.stock_uuid;

    IF OLD.from_section = 'coloring_prod' AND OLD.to_section = 'trx_to_finishing'
    THEN
        UPDATE slider.stock
        SET
        coloring_prod = coloring_prod + OLD.trx_quantity,
        trx_to_finishing = trx_to_finishing - OLD.trx_quantity
        WHERE uuid = OLD.stock_uuid;

        UPDATE zipper.order_description
        SET
        slider_finishing_stock = slider_finishing_stock - OLD.trx_quantity
        WHERE uuid = (SELECT order_description_uuid FROM slider.stock WHERE uuid = OLD.stock_uuid);
        
    END IF;

    IF OLD.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock - CASE WHEN OLD.to_section = 'assembly_stock_to_coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity + CASE WHEN OLD.from_section = 'assembly_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.assembly_stock_uuid;
    END IF;

    RETURN OLD;
END;
$$;
 >   DROP FUNCTION slider.slider_stock_after_transaction_delete();
       slider          postgres    false    12            ~           1255    34636 '   slider_stock_after_transaction_insert()    FUNCTION     r  CREATE FUNCTION slider.slider_stock_after_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = sa_prod - CASE WHEN NEW.from_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END,
        coloring_stock = coloring_stock - CASE WHEN NEW.from_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
    WHERE uuid = NEW.stock_uuid;

    IF NEW.from_section = 'coloring_prod' AND NEW.to_section = 'trx_to_finishing'
    THEN
        UPDATE slider.stock
        SET
        coloring_prod = coloring_prod - NEW.trx_quantity,
        trx_to_finishing = trx_to_finishing + NEW.trx_quantity
        WHERE uuid = NEW.stock_uuid;

        UPDATE zipper.order_description
        SET
        slider_finishing_stock = slider_finishing_stock + NEW.trx_quantity
        WHERE uuid = (SELECT order_description_uuid FROM slider.stock WHERE uuid = NEW.stock_uuid);
    END IF;

    IF NEW.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock + CASE WHEN NEW.to_section = 'assembly_stock_to_coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity - CASE WHEN NEW.from_section = 'assembly_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.assembly_stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 >   DROP FUNCTION slider.slider_stock_after_transaction_insert();
       slider          postgres    false    12                       1255    34637 '   slider_stock_after_transaction_update()    FUNCTION     k
  CREATE FUNCTION slider.slider_stock_after_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.stock
    SET
        
        sa_prod = sa_prod 
        - CASE WHEN NEW.from_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN OLD.from_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_stock = coloring_stock 
        - CASE WHEN NEW.from_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN OLD.from_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
    WHERE uuid = NEW.stock_uuid;

    IF NEW.from_section = 'coloring_prod' AND NEW.to_section = 'trx_to_finishing'
    THEN
        UPDATE slider.stock
        SET
        coloring_prod = coloring_prod - NEW.trx_quantity + OLD.trx_quantity,
        trx_to_finishing = trx_to_finishing + NEW.trx_quantity - OLD.trx_quantity
        WHERE uuid = NEW.stock_uuid;

        UPDATE zipper.order_description
        SET
        slider_finishing_stock = slider_finishing_stock + NEW.trx_quantity - OLD.trx_quantity
        WHERE uuid = (SELECT order_description_uuid FROM slider.stock WHERE uuid = NEW.stock_uuid);
        
    END IF;

    -- assembly_stock_uuid -> OLD
    IF OLD.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock 
            - CASE WHEN OLD.to_section = 'assembly_stock_to_coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity 
            + CASE WHEN OLD.from_section = 'assembly_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.assembly_stock_uuid;
    END IF;

    -- assembly_stock_uuid -> NEW
    IF NEW.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock + CASE WHEN NEW.to_section = 'assembly_stock_to_coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity - CASE WHEN NEW.from_section = 'assembly_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.assembly_stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 >   DROP FUNCTION slider.slider_stock_after_transaction_update();
       slider          postgres    false    12            �           1255    34638 *   order_entry_after_batch_is_drying_update()    FUNCTION     �  CREATE FUNCTION thread.order_entry_after_batch_is_drying_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Handle insert when is_drying_complete is true

    IF TG_OP = 'UPDATE' AND NEW.is_drying_complete = '1' THEN
        -- Update order_entry table
        UPDATE thread.order_entry
        SET production_quantity = production_quantity + NEW.quantity
        WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE batch_uuid = NEW.uuid);

        -- Update batch_entry table
        UPDATE thread.batch_entry
        SET quantity = quantity - NEW.quantity
        WHERE batch_uuid = NEW.uuid;

    -- Handle remove when is_drying_complete changes from true to false

    ELSIF TG_OP = 'UPDATE' AND OLD.is_drying_complete = '1' AND NEW.is_drying_complete = '0' THEN
        -- Update order_entry table
        UPDATE thread.order_entry
        SET production_quantity = production_quantity - OLD.quantity
        WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE batch_uuid = NEW.uuid);

        -- Update batch_entry table
        UPDATE thread.batch_entry
        SET quantity = quantity + OLD.quantity
        WHERE batch_uuid = NEW.uuid;
    END IF;

    RETURN NEW;
END;
$$;
 A   DROP FUNCTION thread.order_entry_after_batch_is_drying_update();
       thread          postgres    false    13            �           1255    34639 *   order_entry_after_batch_is_dyeing_update()    FUNCTION       CREATE FUNCTION thread.order_entry_after_batch_is_dyeing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'Trigger executing for batch UUID: %', NEW.uuid;

    -- Update order_entry
    UPDATE thread.order_entry oe
    SET 
        production_quantity = production_quantity 
        + CASE WHEN (NEW.is_drying_complete = 'true' AND OLD.is_drying_complete = 'false') THEN be.quantity ELSE 0 END 
        - CASE WHEN (NEW.is_drying_complete = 'false' AND OLD.is_drying_complete = 'true') THEN be.quantity ELSE 0 END
    FROM thread.batch_entry be
    LEFT JOIN thread.batch b ON be.batch_uuid = b.uuid
    WHERE b.uuid = NEW.uuid AND oe.uuid = be.order_entry_uuid;
    RAISE NOTICE 'Trigger executed for batch UUID: %', NEW.uuid;
    RETURN NEW;
END;
$$;
 A   DROP FUNCTION thread.order_entry_after_batch_is_dyeing_update();
       thread          postgres    false    13            �           1255    34640 6   order_description_after_dyed_tape_transaction_delete()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_dyed_tape_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update order_description
    UPDATE zipper.order_description
    SET
        tape_received = tape_received + OLD.trx_quantity,
        tape_transferred = tape_transferred - OLD.trx_quantity
    WHERE order_description.uuid = OLD.order_description_uuid;

    RETURN OLD;
END;

$$;
 M   DROP FUNCTION zipper.order_description_after_dyed_tape_transaction_delete();
       zipper          postgres    false    14            �           1255    34641 6   order_description_after_dyed_tape_transaction_insert()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_dyed_tape_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update order_description
    UPDATE zipper.order_description
    SET
        tape_received = tape_received - NEW.trx_quantity,
        tape_transferred = tape_transferred + NEW.trx_quantity
    WHERE order_description.uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 M   DROP FUNCTION zipper.order_description_after_dyed_tape_transaction_insert();
       zipper          postgres    false    14            �           1255    34642 6   order_description_after_dyed_tape_transaction_update()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_dyed_tape_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update order_description
    UPDATE zipper.order_description
    SET
        tape_received = tape_received + OLD.trx_quantity - NEW.trx_quantity,
        tape_transferred = tape_transferred + NEW.trx_quantity - OLD.trx_quantity
    WHERE order_description.uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 M   DROP FUNCTION zipper.order_description_after_dyed_tape_transaction_update();
       zipper          postgres    false    14            �           1255    34643 4   order_description_after_tape_coil_to_dyeing_delete()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.tape_coil
        SET
            quantity_in_coil = CASE WHEN lower(properties.name) = 'nylon' THEN quantity_in_coil + OLD.trx_quantity ELSE quantity_in_coil END,
            quantity = CASE WHEN lower(properties.name) = 'nylon' THEN quantity ELSE quantity + OLD.trx_quantity END
        FROM public.properties
        WHERE tape_coil.uuid = OLD.tape_coil_uuid AND properties.uuid = tape_coil.item_uuid;

        UPDATE zipper.order_description
        SET
            tape_received = tape_received - OLD.trx_quantity
        WHERE uuid = OLD.order_description_uuid;

        RETURN OLD;
    END;
$$;
 K   DROP FUNCTION zipper.order_description_after_tape_coil_to_dyeing_delete();
       zipper          postgres    false    14            �           1255    34644 4   order_description_after_tape_coil_to_dyeing_insert()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE zipper.tape_coil
    SET
        quantity_in_coil = CASE WHEN lower(properties.name) = 'nylon' THEN quantity_in_coil - NEW.trx_quantity ELSE quantity_in_coil END,
        quantity = CASE WHEN lower(properties.name) = 'nylon' THEN quantity ELSE quantity - NEW.trx_quantity END
    FROM public.properties
    WHERE tape_coil.uuid = NEW.tape_coil_uuid AND properties.uuid = tape_coil.item_uuid;
    
    UPDATE zipper.order_description
    SET
        tape_received = tape_received + NEW.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;
$$;
 K   DROP FUNCTION zipper.order_description_after_tape_coil_to_dyeing_insert();
       zipper          postgres    false    14            �           1255    34645 4   order_description_after_tape_coil_to_dyeing_update()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.tape_coil
    SET
        quantity_in_coil = CASE WHEN lower(properties.name) = 'nylon' THEN quantity_in_coil + OLD.trx_quantity - NEW.trx_quantity ELSE quantity_in_coil END,
        quantity = CASE WHEN lower(properties.name) = 'nylon' THEN quantity ELSE quantity + OLD.trx_quantity - NEW.trx_quantity END
    FROM public.properties
    WHERE tape_coil.uuid = NEW.tape_coil_uuid AND properties.uuid = tape_coil.item_uuid;

    UPDATE zipper.order_description
    SET
        tape_received = tape_received - OLD.trx_quantity + NEW.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 K   DROP FUNCTION zipper.order_description_after_tape_coil_to_dyeing_update();
       zipper          postgres    false    14            �           1255    34646    sfg_after_order_entry_delete()    FUNCTION     �   CREATE FUNCTION zipper.sfg_after_order_entry_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM zipper.sfg
    WHERE order_entry_uuid = OLD.uuid;
    RETURN OLD;
END;
$$;
 5   DROP FUNCTION zipper.sfg_after_order_entry_delete();
       zipper          postgres    false    14            �           1255    34647    sfg_after_order_entry_insert()    FUNCTION       CREATE FUNCTION zipper.sfg_after_order_entry_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO zipper.sfg (
        uuid, 
        order_entry_uuid
    ) VALUES (
        NEW.uuid, 
        NEW.uuid
    );
    RETURN NEW;
END;
$$;
 5   DROP FUNCTION zipper.sfg_after_order_entry_insert();
       zipper          postgres    false    14            �           1255    34648 *   sfg_after_sfg_production_delete_function()    FUNCTION     �  CREATE FUNCTION zipper.sfg_after_sfg_production_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    item_name TEXT;
    od_uuid TEXT;
    nylon_stopper_name TEXT;
BEGIN
    -- Fetch item_name and order_description_uuid once
    SELECT vodf.item_name, oe.order_description_uuid, vodf.nylon_stopper_name INTO item_name, od_uuid, nylon_stopper_name
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = OLD.sfg_uuid;

    -- Update order_description based on item_name
    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'vislon' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'plastic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'metallic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity 
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;
    END IF;

    -- Update sfg table
    UPDATE zipper.sfg sfg
    SET 
        teeth_molding_prod = teeth_molding_prod - 
            CASE 
                WHEN OLD.section = 'teeth_molding' THEN 
                    CASE WHEN lower(vodf.item_name) = 'metal' 
                    THEN OLD.production_quantity 
                    ELSE
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity 
                            ELSE OLD.production_quantity_in_kg 
                        END 
                    END
                ELSE 0
            END,
        finishing_stock = finishing_stock + 
            CASE 
                WHEN OLD.section = 'finishing' THEN 
                    CASE
                        WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                        ELSE OLD.production_quantity_in_kg + OLD.wastage 
                    END 
                ELSE 0
            END 
            - 
            CASE 
                WHEN OLD.section = 'teeth_coloring' THEN OLD.production_quantity 
                ELSE 0 
            END,
        finishing_prod = finishing_prod - 
            CASE 
                WHEN OLD.section = 'finishing' THEN OLD.production_quantity 
                ELSE 0
            END,
        teeth_coloring_stock = teeth_coloring_stock + 
            CASE 
                WHEN OLD.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                        ELSE OLD.production_quantity_in_kg + OLD.wastage 
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod - 
            CASE 
                WHEN OLD.section = 'dying_and_iron' THEN OLD.production_quantity 
                ELSE 0 
            END,
        -- teeth_coloring_prod = teeth_coloring_prod - 
        --     CASE 
        --         WHEN OLD.section = 'teeth_coloring' THEN OLD.production_quantity 
        --         ELSE 0 
        --     END,
        coloring_prod = coloring_prod - 
            CASE 
                WHEN OLD.section = 'coloring' THEN OLD.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE sfg.uuid = OLD.sfg_uuid AND sfg.order_entry_uuid = oe.uuid AND oe.order_description_uuid = od_uuid;

    RETURN OLD;
END;
$$;
 A   DROP FUNCTION zipper.sfg_after_sfg_production_delete_function();
       zipper          postgres    false    14            �           1255    34649 *   sfg_after_sfg_production_insert_function()    FUNCTION     �  CREATE FUNCTION zipper.sfg_after_sfg_production_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    item_name TEXT;
    od_uuid TEXT;
    nylon_stopper_name TEXT;
BEGIN
    -- Fetch item_name and order_description_uuid once
    SELECT vodf.item_name, oe.order_description_uuid, vodf.nylon_stopper_name INTO item_name, od_uuid, nylon_stopper_name
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid;

    -- Update order_description based on item_name
    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'vislon' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock -
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'plastic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock -
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'metallic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock -
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;
    END IF;

    -- Update sfg table
    UPDATE zipper.sfg sfg
    SET 
        teeth_molding_prod = teeth_molding_prod + 
            CASE 
                WHEN NEW.section = 'teeth_molding' THEN 
                    CASE WHEN lower(vodf.item_name) = 'metal' 
                    THEN NEW.production_quantity 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                            ELSE NEW.production_quantity_in_kg 
                        END 
                    END
                ELSE 0
            END,
        finishing_stock = finishing_stock - 
            CASE 
                WHEN NEW.section = 'finishing' THEN 
                    CASE
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                        ELSE NEW.production_quantity_in_kg + NEW.wastage 
                    END 
                ELSE 0
            END 
            + 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity 
                ELSE 0 
            END,
        finishing_prod = finishing_prod +
            CASE 
                WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                ELSE 0
            END,
        teeth_coloring_stock = teeth_coloring_stock - 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                        ELSE NEW.production_quantity_in_kg + NEW.wastage 
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod + 
            CASE 
                WHEN NEW.section = 'dying_and_iron' THEN NEW.production_quantity 
                ELSE 0 
            END,
        -- teeth_coloring_prod = teeth_coloring_prod + 
        --     CASE 
        --         WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity 
        --         ELSE 0 
        --     END,
        coloring_prod = coloring_prod + 
            CASE 
                WHEN NEW.section = 'coloring' THEN NEW.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid AND sfg.order_entry_uuid = oe.uuid AND oe.order_description_uuid = od_uuid;

    RETURN NEW;
END;
$$;
 A   DROP FUNCTION zipper.sfg_after_sfg_production_insert_function();
       zipper          postgres    false    14            �           1255    34650 *   sfg_after_sfg_production_update_function()    FUNCTION     D  CREATE FUNCTION zipper.sfg_after_sfg_production_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    item_name TEXT;
    od_uuid TEXT;
    nylon_stopper_name TEXT;
BEGIN
    -- Fetch item_name and order_description_uuid once
    SELECT vodf.item_name, oe.order_description_uuid, vodf.nylon_stopper_name INTO item_name, od_uuid, nylon_stopper_name
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid;

    -- Update order_description based on item_name
    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'vislon' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                            ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                        END
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'plastic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                            ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'metallic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                            ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;
    END IF;

    -- Update sfg table
    UPDATE zipper.sfg sfg
    SET 
        teeth_molding_prod = teeth_molding_prod + 
            CASE 
                WHEN NEW.section = 'teeth_molding' THEN 
                    CASE WHEN lower(vodf.item_name) = 'metal' 
                    THEN NEW.production_quantity - OLD.production_quantity 
                    ELSE
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity - OLD.production_quantity
                            ELSE NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
                        END 
                    END
                ELSE 0
            END,
        finishing_stock = finishing_stock - 
            CASE 
                WHEN NEW.section = 'finishing' THEN 
                    CASE
                        WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                        ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    END 
                ELSE 0
            END 
            + 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0 
            END,
        finishing_prod = finishing_prod + 
            CASE 
                WHEN NEW.section = 'finishing' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0
            END,
        teeth_coloring_stock = teeth_coloring_stock - 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                        ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod + 
            CASE 
                WHEN NEW.section = 'dying_and_iron' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0 
            END,
        -- teeth_coloring_prod = teeth_coloring_prod + 
        --     CASE 
        --         WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity - OLD.production_quantity
        --         ELSE 0 
        --     END,
        coloring_prod = coloring_prod + 
            CASE 
                WHEN NEW.section = 'coloring' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid AND sfg.order_entry_uuid = oe.uuid AND oe.order_description_uuid = od_uuid;

    RETURN NEW;
END;
$$;
 A   DROP FUNCTION zipper.sfg_after_sfg_production_update_function();
       zipper          postgres    false    14            �           1255    34651 +   sfg_after_sfg_transaction_delete_function()    FUNCTION     (  CREATE FUNCTION zipper.sfg_after_sfg_transaction_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tocs_uuid INT;
BEGIN
    -- Updating stocks based on OLD.trx_to
    UPDATE zipper.sfg
     SET
        teeth_molding_stock = teeth_molding_stock 
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock 
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,
        finishing_stock = finishing_stock 
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,
        warehouse = warehouse 
            - CASE WHEN OLD.trx_to = 'warehouse' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = OLD.sfg_uuid;

    -- Updating productions based on OLD.trx_from
    UPDATE zipper.sfg SET
        teeth_molding_prod = teeth_molding_prod + 
        CASE WHEN OLD.trx_from = 'teeth_molding_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,

        teeth_coloring_prod = teeth_coloring_prod + 
        CASE WHEN OLD.trx_from = 'teeth_coloring_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,

        finishing_prod = finishing_prod + 
        CASE WHEN OLD.trx_from = 'finishing_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,

        warehouse = warehouse + 
        CASE WHEN OLD.trx_from = 'warehouse' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = OLD.sfg_uuid;

    RETURN OLD;
END;
$$;
 B   DROP FUNCTION zipper.sfg_after_sfg_transaction_delete_function();
       zipper          postgres    false    14            �           1255    34652 +   sfg_after_sfg_transaction_insert_function()    FUNCTION     *  CREATE FUNCTION zipper.sfg_after_sfg_transaction_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tocs_uuid INT;
BEGIN
    -- Updating stocks based on NEW.trx_to
    UPDATE zipper.sfg SET
        teeth_molding_stock = teeth_molding_stock + 
        CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        teeth_coloring_stock = teeth_coloring_stock + 
        CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        finishing_stock = finishing_stock + 
        CASE WHEN NEW.trx_to = 'finishing_stock' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        warehouse = warehouse + 
        CASE WHEN NEW.trx_to = 'warehouse' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;

    -- Updating productions based on NEW.trx_from
    UPDATE zipper.sfg SET
        teeth_molding_prod = teeth_molding_prod - 
        CASE WHEN NEW.trx_from = 'teeth_molding_prod' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        teeth_coloring_prod = teeth_coloring_prod - 
        CASE WHEN NEW.trx_from = 'teeth_coloring_prod' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        finishing_prod = finishing_prod - 
        CASE WHEN NEW.trx_from = 'finishing_prod' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        warehouse = warehouse - 
        CASE WHEN NEW.trx_from = 'warehouse' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;

    RETURN NEW;
END;
$$;
 B   DROP FUNCTION zipper.sfg_after_sfg_transaction_insert_function();
       zipper          postgres    false    14            �           1255    34653 +   sfg_after_sfg_transaction_update_function()    FUNCTION     ?  CREATE FUNCTION zipper.sfg_after_sfg_transaction_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tocs_uuid INT;
BEGIN
    -- Updating stocks based on OLD.trx_to and NEW.trx_to
    UPDATE zipper.sfg SET
        teeth_molding_stock = teeth_molding_stock 
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock 
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        finishing_stock = finishing_stock 
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'finishing_stock' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        warehouse = warehouse 
            - CASE WHEN OLD.trx_to = 'warehouse' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'warehouse' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;

    -- Updating productions based on OLD.trx_from and NEW.trx_from
    UPDATE zipper.sfg SET
        teeth_molding_prod = teeth_molding_prod 
            + CASE WHEN OLD.trx_from = 'teeth_molding_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'teeth_molding_prod' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod 
            + CASE WHEN OLD.trx_from = 'teeth_coloring_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'teeth_coloring_prod' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        finishing_prod = finishing_prod 
            + CASE WHEN OLD.trx_from = 'finishing_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'finishing_prod' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        warehouse = warehouse 
            + CASE WHEN OLD.trx_from = 'warehouse' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'warehouse' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
        WHERE uuid = NEW.sfg_uuid;
    
    RETURN NEW;
END;
$$;
 B   DROP FUNCTION zipper.sfg_after_sfg_transaction_update_function();
       zipper          postgres    false    14            �           1255    34654 A   stock_after_material_trx_against_order_description_delete_funct()    FUNCTION     =  CREATE FUNCTION zipper.stock_after_material_trx_against_order_description_delete_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update material,stock
    UPDATE material.stock
    SET
        stock = stock + OLD.trx_quantity
    WHERE material_uuid = OLD.material_uuid;

    RETURN OLD;
END;
$$;
 X   DROP FUNCTION zipper.stock_after_material_trx_against_order_description_delete_funct();
       zipper          postgres    false    14            �           1255    34655 A   stock_after_material_trx_against_order_description_insert_funct()    FUNCTION     =  CREATE FUNCTION zipper.stock_after_material_trx_against_order_description_insert_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update material,stock
    UPDATE material.stock
    SET
        stock = stock - NEW.trx_quantity
    WHERE material_uuid = NEW.material_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION zipper.stock_after_material_trx_against_order_description_insert_funct();
       zipper          postgres    false    14            �           1255    34656 A   stock_after_material_trx_against_order_description_update_funct()    FUNCTION     i  CREATE FUNCTION zipper.stock_after_material_trx_against_order_description_update_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update material,stock
    UPDATE material.stock
    SET
        stock = stock 
            - NEW.trx_quantity
            + OLD.trx_quantity
    WHERE material_uuid = NEW.material_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION zipper.stock_after_material_trx_against_order_description_update_funct();
       zipper          postgres    false    14            �           1255    34657 &   tape_coil_after_tape_coil_production()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_coil_production() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Production
        quantity = quantity 
        + CASE WHEN NEW.section = 'tape' THEN NEW.production_quantity ELSE 0 END,

        -- Coil Production
        trx_quantity_in_coil = trx_quantity_in_coil 
        - CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,
        quantity_in_coil = quantity_in_coil
        + CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity ELSE 0 END,

        -- Tape Or Production for Stock
        trx_quantity_in_dying = trx_quantity_in_dying
        - CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,
        stock_quantity = stock_quantity 
        + CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity ELSE 0 END

    WHERE uuid = NEW.tape_coil_uuid;

    RETURN NEW;
END;
$$;
 =   DROP FUNCTION zipper.tape_coil_after_tape_coil_production();
       zipper          postgres    false    14            �           1255    34658 -   tape_coil_after_tape_coil_production_delete()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_coil_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Production
        quantity = quantity 
        - CASE WHEN OLD.section = 'tape' THEN OLD.production_quantity ELSE 0 END,

        -- Coil Production
        trx_quantity_in_coil = trx_quantity_in_coil 
        + CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity + OLD.wastage ELSE 0 END,
        quantity_in_coil = quantity_in_coil
        - CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity ELSE 0 END,

        -- Tape Or Production for Stock
        trx_quantity_in_dying = trx_quantity_in_dying
        + CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity  + OLD.wastage ELSE 0 END,
        stock_quantity = stock_quantity 
        - CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity ELSE 0 END

    WHERE uuid = OLD.tape_coil_uuid;

    RETURN OLD;
END;
$$;
 D   DROP FUNCTION zipper.tape_coil_after_tape_coil_production_delete();
       zipper          postgres    false    14            �           1255    34659 -   tape_coil_after_tape_coil_production_update()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_coil_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Production
        quantity = quantity 
        + CASE WHEN OLD.section = 'tape' THEN OLD.production_quantity ELSE 0 END
        - CASE WHEN NEW.section = 'tape' THEN NEW.production_quantity ELSE 0 END,

        -- Coil Production
        trx_quantity_in_coil = trx_quantity_in_coil 
        + CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity + OLD.wastage ELSE 0 END
        - CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,

        quantity_in_coil = quantity_in_coil
        - CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity ELSE 0 END
        + CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity ELSE 0 END,

        -- Tape Or Production for Stock
        trx_quantity_in_dying = trx_quantity_in_dying
        + CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity + OLD.wastage ELSE 0 END
        - CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,

        stock_quantity = stock_quantity 
        - CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity ELSE 0 END
        + CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity ELSE 0 END

    WHERE uuid = NEW.tape_coil_uuid;

    RETURN NEW;
END;
$$;
 D   DROP FUNCTION zipper.tape_coil_after_tape_coil_production_update();
       zipper          postgres    false    14            �           1255    34660 !   tape_coil_after_tape_trx_delete()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_trx_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Trx to Coil Or Dyeing
        quantity = quantity + CASE WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil' THEN OLD.trx_quantity ELSE 0 END,
        -- Coil To Dyeing
        quantity_in_coil = quantity_in_coil + CASE WHEN OLD.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties WHERE zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN OLD.trx_quantity ELSE 0 END,
        -- Tape AND Coil Dyeing Trx
        trx_quantity_in_dying = trx_quantity_in_dying 
        - CASE WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil_dyeing' THEN OLD.trx_quantity ELSE 0 END
        + CASE WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity ELSE 0 END,
        -- Tape to Coil Trx 
        trx_quantity_in_coil = trx_quantity_in_coil - CASE WHEN OLD.to_section = 'coil' THEN OLD.trx_quantity ELSE 0 END,
        -- Dyed Tape or Coil Stock
        stock_quantity = stock_quantity - CASE WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity ELSE 0 END
    WHERE uuid = OLD.tape_coil_uuid;
    RETURN OLD;
END;
$$;
 8   DROP FUNCTION zipper.tape_coil_after_tape_trx_delete();
       zipper          postgres    false    14            �           1255    34661 !   tape_coil_after_tape_trx_insert()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_trx_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Trx to Coil Or Dyeing
        quantity = quantity - CASE WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil' THEN NEW.trx_quantity ELSE 0 END,
        -- Coil To Dyeing
        quantity_in_coil = quantity_in_coil 
        - CASE WHEN NEW.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties where zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN NEW.trx_quantity ELSE 0 END,
        -- Tape AND Coil Dyeing Trx
        trx_quantity_in_dying = trx_quantity_in_dying 
        + CASE WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil_dyeing' THEN NEW.trx_quantity ELSE 0 END 
        - CASE WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity ELSE 0 END,
        
        -- Tape to Coil Trx 
        trx_quantity_in_coil = trx_quantity_in_coil + CASE WHEN NEW.to_section = 'coil' THEN NEW.trx_quantity ELSE 0 END,

        -- Dyed Tape or Coil Stock
        stock_quantity = stock_quantity + CASE WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity ELSE 0 END

    WHERE uuid = NEW.tape_coil_uuid;
RETURN NEW;
END;
$$;
 8   DROP FUNCTION zipper.tape_coil_after_tape_trx_insert();
       zipper          postgres    false    14            �           1255    34662 !   tape_coil_after_tape_trx_update()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_trx_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Trx to Coil Or Dyeing
        quantity = quantity - CASE 
            WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil' THEN NEW.trx_quantity 
            ELSE 0 
        END + CASE 
            WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Coil To Dyeing
        quantity_in_coil = quantity_in_coil - CASE 
            WHEN NEW.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties WHERE zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN NEW.trx_quantity 
            ELSE 0 
        END + CASE 
            WHEN OLD.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties WHERE zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Tape AND Coil Dyeing Trx
        trx_quantity_in_dying = trx_quantity_in_dying + CASE 
            WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil_dyeing' THEN NEW.trx_quantity 
            ELSE 0 
        END - CASE 
            WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil_dyeing' THEN OLD.trx_quantity 
            ELSE 0 
        END
        - CASE 
            WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity 
            ELSE 0 
        END + CASE 
            WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Tape to Coil Trx 
        trx_quantity_in_coil = trx_quantity_in_coil + CASE 
            WHEN NEW.to_section = 'coil' THEN NEW.trx_quantity 
            ELSE 0 
        END - CASE 
            WHEN OLD.to_section = 'coil' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Dyed Tape or Coil Stock
        stock_quantity = stock_quantity + CASE 
            WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity 
            ELSE 0 
        END - CASE 
            WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity 
            ELSE 0 
        END
    WHERE uuid = NEW.tape_coil_uuid;
    RETURN NEW;
END;
$$;
 8   DROP FUNCTION zipper.tape_coil_after_tape_trx_update();
       zipper          postgres    false    14            �           1255    34663 A   tape_coil_and_order_description_after_dyed_tape_transaction_del()    FUNCTION       CREATE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update zipper.tape_coil
    UPDATE zipper.tape_coil
    SET
        stock_quantity = stock_quantity + OLD.trx_quantity
    WHERE uuid = OLD.tape_coil_uuid;
    -- Update zipper.order_description
    UPDATE zipper.order_description
    SET
        tape_transferred = tape_transferred - OLD.trx_quantity
    WHERE uuid = OLD.order_description_uuid;

    RETURN OLD;
END;

$$;
 X   DROP FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_del();
       zipper          postgres    false    14            �           1255    34664 A   tape_coil_and_order_description_after_dyed_tape_transaction_ins()    FUNCTION       CREATE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil
    UPDATE zipper.tape_coil
    SET
        stock_quantity = stock_quantity - NEW.trx_quantity
    WHERE uuid = NEW.tape_coil_uuid;
    -- Update zipper.order_description
    UPDATE zipper.order_description
    SET
        tape_transferred = tape_transferred + NEW.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 X   DROP FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_ins();
       zipper          postgres    false    14            �           1255    34665 A   tape_coil_and_order_description_after_dyed_tape_transaction_upd()    FUNCTION     2  CREATE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update zipper.tape_coil
    UPDATE zipper.tape_coil
    SET
        stock_quantity = stock_quantity - NEW.trx_quantity + OLD.trx_quantity
    WHERE uuid = NEW.tape_coil_uuid;
    -- Update zipper.order_description
    UPDATE zipper.order_description
    SET
        tape_transferred = tape_transferred + NEW.trx_quantity - OLD.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 X   DROP FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_upd();
       zipper          postgres    false    14            �            1259    34666    bank    TABLE     /  CREATE TABLE commercial.bank (
    uuid text NOT NULL,
    name text NOT NULL,
    swift_code text NOT NULL,
    address text,
    policy text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    created_by text,
    routing_no text
);
    DROP TABLE commercial.bank;
    
   commercial         heap    postgres    false    5            �            1259    34671    lc_sequence    SEQUENCE     x   CREATE SEQUENCE commercial.lc_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE commercial.lc_sequence;
    
   commercial          postgres    false    5            �            1259    34672    lc    TABLE     }  CREATE TABLE commercial.lc (
    uuid text NOT NULL,
    party_uuid text,
    lc_number text NOT NULL,
    lc_date timestamp without time zone NOT NULL,
    payment_value numeric(20,4) DEFAULT 0,
    payment_date timestamp without time zone,
    ldbc_fdbc text,
    acceptance_date timestamp without time zone,
    maturity_date timestamp without time zone,
    commercial_executive text NOT NULL,
    party_bank text NOT NULL,
    production_complete integer DEFAULT 0,
    lc_cancel integer DEFAULT 0,
    handover_date timestamp without time zone,
    shipment_date timestamp without time zone,
    expiry_date timestamp without time zone,
    ud_no text,
    ud_received text,
    at_sight text NOT NULL,
    amd_date timestamp without time zone,
    amd_count integer DEFAULT 0,
    problematical integer DEFAULT 0,
    epz integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    id integer DEFAULT nextval('commercial.lc_sequence'::regclass) NOT NULL,
    document_receive_date timestamp without time zone,
    is_rtgs integer DEFAULT 0
);
    DROP TABLE commercial.lc;
    
   commercial         heap    postgres    false    220    5            �            1259    34685    pi_sequence    SEQUENCE     x   CREATE SEQUENCE commercial.pi_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE commercial.pi_sequence;
    
   commercial          postgres    false    5            �            1259    34686    pi_cash    TABLE     �  CREATE TABLE commercial.pi_cash (
    uuid text NOT NULL,
    id integer DEFAULT nextval('commercial.pi_sequence'::regclass) NOT NULL,
    lc_uuid text,
    order_info_uuids text NOT NULL,
    marketing_uuid text,
    party_uuid text,
    merchandiser_uuid text,
    factory_uuid text,
    bank_uuid text,
    validity integer DEFAULT 0,
    payment integer DEFAULT 0,
    is_pi integer DEFAULT 0,
    conversion_rate numeric(20,4) DEFAULT 0,
    receive_amount numeric(20,4) DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL,
    thread_order_info_uuids text
);
    DROP TABLE commercial.pi_cash;
    
   commercial         heap    postgres    false    222    5            �            1259    34698    pi_cash_entry    TABLE     .  CREATE TABLE commercial.pi_cash_entry (
    uuid text NOT NULL,
    pi_cash_uuid text,
    sfg_uuid text,
    pi_cash_quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    thread_order_entry_uuid text
);
 %   DROP TABLE commercial.pi_cash_entry;
    
   commercial         heap    postgres    false    5            �            1259    34703    challan_sequence    SEQUENCE     {   CREATE SEQUENCE delivery.challan_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE delivery.challan_sequence;
       delivery          postgres    false    6            �            1259    34704    challan    TABLE     �  CREATE TABLE delivery.challan (
    uuid text NOT NULL,
    carton_quantity integer NOT NULL,
    assign_to text,
    receive_status integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    id integer DEFAULT nextval('delivery.challan_sequence'::regclass),
    gate_pass integer DEFAULT 0,
    order_info_uuid text
);
    DROP TABLE delivery.challan;
       delivery         heap    postgres    false    225    6            �            1259    34712    challan_entry    TABLE     �   CREATE TABLE delivery.challan_entry (
    uuid text NOT NULL,
    challan_uuid text,
    packing_list_uuid text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 #   DROP TABLE delivery.challan_entry;
       delivery         heap    postgres    false    6            �            1259    34717    packing_list_sequence    SEQUENCE     �   CREATE SEQUENCE delivery.packing_list_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE delivery.packing_list_sequence;
       delivery          postgres    false    6            �            1259    34718    packing_list    TABLE     �  CREATE TABLE delivery.packing_list (
    uuid text NOT NULL,
    carton_size text NOT NULL,
    carton_weight text NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    order_info_uuid text,
    id integer DEFAULT nextval('delivery.packing_list_sequence'::regclass),
    challan_uuid text
);
 "   DROP TABLE delivery.packing_list;
       delivery         heap    postgres    false    228    6            �            1259    34724    packing_list_entry    TABLE     Y  CREATE TABLE delivery.packing_list_entry (
    uuid text NOT NULL,
    packing_list_uuid text,
    sfg_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    short_quantity integer DEFAULT 0,
    reject_quantity integer DEFAULT 0
);
 (   DROP TABLE delivery.packing_list_entry;
       delivery         heap    postgres    false    6            �            1259    34731    users    TABLE     C  CREATE TABLE hr.users (
    uuid text NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    pass text NOT NULL,
    designation_uuid text,
    can_access text,
    ext text,
    phone text,
    created_at text NOT NULL,
    updated_at text,
    status text DEFAULT 0,
    remarks text,
    department_uuid text
);
    DROP TABLE hr.users;
       hr         heap    postgres    false    8            �            1259    34737    buyer    TABLE     �   CREATE TABLE public.buyer (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE public.buyer;
       public         heap    postgres    false    15            �            1259    34742    factory    TABLE       CREATE TABLE public.factory (
    uuid text NOT NULL,
    party_uuid text,
    name text NOT NULL,
    phone text,
    address text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text,
    remarks text
);
    DROP TABLE public.factory;
       public         heap    postgres    false    15            �            1259    34747 	   marketing    TABLE       CREATE TABLE public.marketing (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    user_uuid text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE public.marketing;
       public         heap    postgres    false    15            �            1259    34752    merchandiser    TABLE     $  CREATE TABLE public.merchandiser (
    uuid text NOT NULL,
    party_uuid text,
    name text NOT NULL,
    email text,
    phone text,
    address text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text,
    remarks text
);
     DROP TABLE public.merchandiser;
       public         heap    postgres    false    15            �            1259    34757    party    TABLE       CREATE TABLE public.party (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text,
    address text
);
    DROP TABLE public.party;
       public         heap    postgres    false    15            �            1259    34762 
   properties    TABLE     -  CREATE TABLE public.properties (
    uuid text NOT NULL,
    item_for text NOT NULL,
    type text NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE public.properties;
       public         heap    postgres    false    15            �            1259    34767    stock    TABLE     a  CREATE TABLE slider.stock (
    uuid text NOT NULL,
    order_quantity numeric(20,4) DEFAULT 0,
    body_quantity numeric(20,4) DEFAULT 0,
    cap_quantity numeric(20,4) DEFAULT 0,
    puller_quantity numeric(20,4) DEFAULT 0,
    link_quantity numeric(20,4) DEFAULT 0,
    sa_prod numeric(20,4) DEFAULT 0,
    coloring_stock numeric(20,4) DEFAULT 0,
    coloring_prod numeric(20,4) DEFAULT 0,
    trx_to_finishing numeric(20,4) DEFAULT 0,
    u_top_quantity numeric(20,4) DEFAULT 0,
    h_bottom_quantity numeric(20,4) DEFAULT 0,
    box_pin_quantity numeric(20,4) DEFAULT 0,
    two_way_pin_quantity numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    quantity_in_sa numeric(20,4) DEFAULT 0,
    order_description_uuid text,
    finishing_stock numeric(20,4) DEFAULT 0
);
    DROP TABLE slider.stock;
       slider         heap    postgres    false    12            �            1259    34787    order_description    TABLE     �  CREATE TABLE zipper.order_description (
    uuid text NOT NULL,
    order_info_uuid text,
    item text,
    zipper_number text,
    end_type text,
    lock_type text,
    puller_type text,
    teeth_color text,
    puller_color text,
    special_requirement text,
    hand text,
    coloring_type text,
    is_slider_provided integer DEFAULT 0,
    slider text,
    slider_starting_section_enum zipper.slider_starting_section_enum,
    top_stopper text,
    bottom_stopper text,
    logo_type text,
    is_logo_body integer DEFAULT 0 NOT NULL,
    is_logo_puller integer DEFAULT 0 NOT NULL,
    description text,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    slider_body_shape text,
    slider_link text,
    end_user text,
    garment text,
    light_preference text,
    garments_wash text,
    created_by text,
    garments_remarks text,
    tape_received numeric(20,4) DEFAULT 0 NOT NULL,
    tape_transferred numeric(20,4) DEFAULT 0 NOT NULL,
    slider_finishing_stock numeric(20,4) DEFAULT 0 NOT NULL,
    nylon_stopper text,
    tape_coil_uuid text,
    teeth_type text
);
 %   DROP TABLE zipper.order_description;
       zipper         heap    postgres    false    1019    14            �            1259    34799    order_entry    TABLE     l  CREATE TABLE zipper.order_entry (
    uuid text NOT NULL,
    order_description_uuid text,
    style text NOT NULL,
    color text NOT NULL,
    size text NOT NULL,
    quantity numeric(20,4) NOT NULL,
    company_price numeric(20,4) DEFAULT 0 NOT NULL,
    party_price numeric(20,4) DEFAULT 0 NOT NULL,
    status integer DEFAULT 1,
    swatch_status_enum zipper.swatch_status_enum DEFAULT 'pending'::zipper.swatch_status_enum,
    swatch_approval_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    bleaching text
);
    DROP TABLE zipper.order_entry;
       zipper         heap    postgres    false    1022    1022    14            �            1259    34808    order_info_sequence    SEQUENCE     |   CREATE SEQUENCE zipper.order_info_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE zipper.order_info_sequence;
       zipper          postgres    false    14            �            1259    34809 
   order_info    TABLE     �  CREATE TABLE zipper.order_info (
    uuid text NOT NULL,
    id integer DEFAULT nextval('zipper.order_info_sequence'::regclass) NOT NULL,
    reference_order_info_uuid text,
    buyer_uuid text,
    party_uuid text,
    marketing_uuid text,
    merchandiser_uuid text,
    factory_uuid text,
    is_sample integer DEFAULT 0,
    is_bill integer DEFAULT 0,
    is_cash integer DEFAULT 0,
    marketing_priority text,
    factory_priority text,
    status integer DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    conversion_rate numeric(20,4) DEFAULT 0 NOT NULL,
    print_in zipper.print_in_enum DEFAULT 'portrait'::zipper.print_in_enum
);
    DROP TABLE zipper.order_info;
       zipper         heap    postgres    false    241    1016    14    1016            �            1259    34821    sfg    TABLE     �  CREATE TABLE zipper.sfg (
    uuid text NOT NULL,
    order_entry_uuid text,
    recipe_uuid text,
    dying_and_iron_prod numeric(20,4) DEFAULT 0,
    teeth_molding_stock numeric(20,4) DEFAULT 0,
    teeth_molding_prod numeric(20,4) DEFAULT 0,
    teeth_coloring_stock numeric(20,4) DEFAULT 0,
    teeth_coloring_prod numeric(20,4) DEFAULT 0,
    finishing_stock numeric(20,4) DEFAULT 0,
    finishing_prod numeric(20,4) DEFAULT 0,
    coloring_prod numeric(20,4) DEFAULT 0,
    warehouse numeric(20,4) DEFAULT 0 NOT NULL,
    delivered numeric(20,4) DEFAULT 0 NOT NULL,
    pi numeric(20,4) DEFAULT 0 NOT NULL,
    remarks text,
    short_quantity integer DEFAULT 0,
    reject_quantity integer DEFAULT 0
);
    DROP TABLE zipper.sfg;
       zipper         heap    postgres    false    14            �            1259    34839 	   tape_coil    TABLE     �  CREATE TABLE zipper.tape_coil (
    uuid text NOT NULL,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    trx_quantity_in_coil numeric(20,4) DEFAULT 0 NOT NULL,
    quantity_in_coil numeric(20,4) DEFAULT 0 NOT NULL,
    remarks text,
    item_uuid text,
    zipper_number_uuid text,
    name text NOT NULL,
    raw_per_kg_meter numeric(20,4) DEFAULT 0 NOT NULL,
    dyed_per_kg_meter numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    is_import text,
    is_reverse text,
    trx_quantity_in_dying numeric(20,4) DEFAULT 0 NOT NULL,
    stock_quantity numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE zipper.tape_coil;
       zipper         heap    postgres    false    14            �            1259    34851    v_order_details_full    VIEW     S  CREATE VIEW zipper.v_order_details_full AS
 SELECT order_info.uuid AS order_info_uuid,
    concat('Z', to_char(order_info.created_at, 'YY'::text), '-', lpad((order_info.id)::text, 4, '0'::text)) AS order_number,
    order_description.uuid AS order_description_uuid,
    order_description.tape_received,
    order_description.tape_transferred,
    order_description.slider_finishing_stock,
    order_info.marketing_uuid,
    marketing.name AS marketing_name,
    order_info.buyer_uuid,
    buyer.name AS buyer_name,
    order_info.merchandiser_uuid,
    merchandiser.name AS merchandiser_name,
    order_info.factory_uuid,
    factory.name AS factory_name,
    factory.address AS factory_address,
    order_info.party_uuid,
    party.name AS party_name,
    order_info.created_by AS created_by_uuid,
    users.name AS created_by_name,
    order_info.is_cash,
    order_info.is_bill,
    order_info.is_sample,
    order_info.status AS order_status,
    order_info.created_at,
    order_info.updated_at,
    order_info.print_in,
    concat(op_item.short_name, op_nylon_stopper.short_name, '-', op_zipper.short_name, '-', op_end.short_name, '-', op_puller.short_name) AS item_description,
    order_description.item,
    op_item.name AS item_name,
    op_item.short_name AS item_short_name,
    order_description.nylon_stopper,
    op_nylon_stopper.name AS nylon_stopper_name,
    op_nylon_stopper.short_name AS nylon_stopper_short_name,
    order_description.zipper_number,
    op_zipper.name AS zipper_number_name,
    op_zipper.short_name AS zipper_number_short_name,
    order_description.end_type,
    op_end.name AS end_type_name,
    op_end.short_name AS end_type_short_name,
    order_description.puller_type,
    op_puller.name AS puller_type_name,
    op_puller.short_name AS puller_type_short_name,
    order_description.lock_type,
    op_lock.name AS lock_type_name,
    op_lock.short_name AS lock_type_short_name,
    order_description.teeth_color,
    op_teeth_color.name AS teeth_color_name,
    op_teeth_color.short_name AS teeth_color_short_name,
    order_description.puller_color,
    op_puller_color.name AS puller_color_name,
    op_puller_color.short_name AS puller_color_short_name,
    order_description.hand,
    op_hand.name AS hand_name,
    op_hand.short_name AS hand_short_name,
    order_description.coloring_type,
    op_coloring.name AS coloring_type_name,
    op_coloring.short_name AS coloring_type_short_name,
    order_description.is_slider_provided,
    order_description.slider,
    op_slider.name AS slider_name,
    op_slider.short_name AS slider_short_name,
    order_description.slider_starting_section_enum AS slider_starting_section,
    order_description.top_stopper,
    op_top_stopper.name AS top_stopper_name,
    op_top_stopper.short_name AS top_stopper_short_name,
    order_description.bottom_stopper,
    op_bottom_stopper.name AS bottom_stopper_name,
    op_bottom_stopper.short_name AS bottom_stopper_short_name,
    order_description.logo_type,
    op_logo.name AS logo_type_name,
    op_logo.short_name AS logo_type_short_name,
    order_description.is_logo_body,
    order_description.is_logo_puller,
    order_description.special_requirement,
    order_description.description,
    order_description.status AS order_description_status,
    order_description.created_at AS order_description_created_at,
    order_description.updated_at AS order_description_updated_at,
    order_description.remarks,
    order_description.slider_body_shape,
    op_slider_body_shape.name AS slider_body_shape_name,
    op_slider_body_shape.short_name AS slider_body_shape_short_name,
    order_description.end_user,
    op_end_user.name AS end_user_name,
    op_end_user.short_name AS end_user_short_name,
    order_description.garment,
    order_description.light_preference,
    op_light_preference.name AS light_preference_name,
    op_light_preference.short_name AS light_preference_short_name,
    order_description.garments_wash,
    order_description.slider_link,
    op_slider_link.name AS slider_link_name,
    op_slider_link.short_name AS slider_link_short_name,
    order_info.marketing_priority,
    order_info.factory_priority,
    order_description.garments_remarks,
    stock.uuid AS stock_uuid,
    stock.order_quantity AS stock_order_quantity,
    order_description.tape_coil_uuid,
    tc.name AS tape_name,
    order_description.teeth_type,
    op_teeth_type.name AS teeth_type_name,
    op_teeth_type.short_name AS teeth_type_short_name
   FROM ((((((((((((((((((((((((((((zipper.order_info
     LEFT JOIN zipper.order_description ON ((order_description.order_info_uuid = order_info.uuid)))
     LEFT JOIN public.marketing ON ((marketing.uuid = order_info.marketing_uuid)))
     LEFT JOIN public.buyer ON ((buyer.uuid = order_info.buyer_uuid)))
     LEFT JOIN public.merchandiser ON ((merchandiser.uuid = order_info.merchandiser_uuid)))
     LEFT JOIN public.factory ON ((factory.uuid = order_info.factory_uuid)))
     LEFT JOIN hr.users users ON ((users.uuid = order_info.created_by)))
     LEFT JOIN public.party ON ((party.uuid = order_info.party_uuid)))
     LEFT JOIN public.properties op_item ON ((op_item.uuid = order_description.item)))
     LEFT JOIN public.properties op_nylon_stopper ON ((op_nylon_stopper.uuid = order_description.nylon_stopper)))
     LEFT JOIN public.properties op_zipper ON ((op_zipper.uuid = order_description.zipper_number)))
     LEFT JOIN public.properties op_end ON ((op_end.uuid = order_description.end_type)))
     LEFT JOIN public.properties op_puller ON ((op_puller.uuid = order_description.puller_type)))
     LEFT JOIN public.properties op_lock ON ((op_lock.uuid = order_description.lock_type)))
     LEFT JOIN public.properties op_teeth_color ON ((op_teeth_color.uuid = order_description.teeth_color)))
     LEFT JOIN public.properties op_puller_color ON ((op_puller_color.uuid = order_description.puller_color)))
     LEFT JOIN public.properties op_hand ON ((op_hand.uuid = order_description.hand)))
     LEFT JOIN public.properties op_coloring ON ((op_coloring.uuid = order_description.coloring_type)))
     LEFT JOIN public.properties op_slider ON ((op_slider.uuid = order_description.slider)))
     LEFT JOIN public.properties op_top_stopper ON ((op_top_stopper.uuid = order_description.top_stopper)))
     LEFT JOIN public.properties op_bottom_stopper ON ((op_bottom_stopper.uuid = order_description.bottom_stopper)))
     LEFT JOIN public.properties op_logo ON ((op_logo.uuid = order_description.logo_type)))
     LEFT JOIN public.properties op_slider_body_shape ON ((op_slider_body_shape.uuid = order_description.slider_body_shape)))
     LEFT JOIN public.properties op_slider_link ON ((op_slider_link.uuid = order_description.slider_link)))
     LEFT JOIN public.properties op_end_user ON ((op_end_user.uuid = order_description.end_user)))
     LEFT JOIN public.properties op_light_preference ON ((op_light_preference.uuid = order_description.light_preference)))
     LEFT JOIN slider.stock ON ((stock.order_description_uuid = order_description.uuid)))
     LEFT JOIN zipper.tape_coil tc ON ((tc.uuid = order_description.tape_coil_uuid)))
     LEFT JOIN public.properties op_teeth_type ON ((op_teeth_type.uuid = order_description.teeth_type)));
 '   DROP VIEW zipper.v_order_details_full;
       zipper          postgres    false    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    239    238    238    238    237    237    237    236    236    235    235    234    234    233    233    233    232    232    231    231    242    242    242    242    242    242    242    242    242    242    242    242    242    242    242    244    244    242    242    14    1019    1016            �            1259    34856    v_packing_list    VIEW     �  CREATE VIEW delivery.v_packing_list AS
 SELECT pl.id AS packing_list_id,
    pl.uuid AS packing_list_uuid,
    concat('PL', to_char(pl.created_at, 'YY'::text), '-', lpad((pl.id)::text, 4, '0'::text)) AS packing_number,
    pl.carton_size,
    pl.carton_weight,
    pl.order_info_uuid,
    pl.challan_uuid,
    pl.created_by AS created_by_uuid,
    users.name AS created_by_name,
    pl.created_at,
    pl.updated_at,
    pl.remarks,
    ple.uuid AS packing_list_entry_uuid,
    ple.sfg_uuid,
    ple.quantity,
    ple.short_quantity,
    ple.reject_quantity,
    ple.created_at AS entry_created_at,
    ple.updated_at AS entry_updated_at,
    ple.remarks AS entry_remarks,
    oe.uuid AS order_entry_uuid,
    oe.style,
    oe.color,
    oe.size,
    concat(oe.style, ' / ', oe.color, ' / ', oe.size) AS style_color_size,
    oe.quantity AS order_quantity,
    vodf.order_description_uuid,
    vodf.order_number,
    vodf.item_description,
    sfg.warehouse,
    sfg.delivered,
    (oe.quantity - sfg.warehouse) AS balance_quantity
   FROM (((((delivery.packing_list pl
     LEFT JOIN delivery.packing_list_entry ple ON ((ple.packing_list_uuid = pl.uuid)))
     LEFT JOIN hr.users ON ((users.uuid = pl.created_by)))
     LEFT JOIN zipper.sfg ON ((sfg.uuid = ple.sfg_uuid)))
     LEFT JOIN zipper.order_entry oe ON ((oe.uuid = sfg.order_entry_uuid)))
     LEFT JOIN zipper.v_order_details_full vodf ON ((vodf.order_description_uuid = oe.order_description_uuid)));
 #   DROP VIEW delivery.v_packing_list;
       delivery          postgres    false    240    243    230    229    229    229    243    243    243    230    229    229    230    230    230    245    245    245    230    231    229    229    231    240    229    229    240    240    240    230    229    230    230    240    6            �            1259    34861    migrations_details    TABLE     t   CREATE TABLE drizzle.migrations_details (
    id integer NOT NULL,
    hash text NOT NULL,
    created_at bigint
);
 '   DROP TABLE drizzle.migrations_details;
       drizzle         heap    postgres    false    7            �            1259    34866    migrations_details_id_seq    SEQUENCE     �   CREATE SEQUENCE drizzle.migrations_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE drizzle.migrations_details_id_seq;
       drizzle          postgres    false    7    247            �           0    0    migrations_details_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE drizzle.migrations_details_id_seq OWNED BY drizzle.migrations_details.id;
          drizzle          postgres    false    248            �            1259    34867 
   department    TABLE     �   CREATE TABLE hr.department (
    uuid text NOT NULL,
    department text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE hr.department;
       hr         heap    postgres    false    8            �            1259    34872    designation    TABLE     �   CREATE TABLE hr.designation (
    uuid text NOT NULL,
    designation text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE hr.designation;
       hr         heap    postgres    false    8            �            1259    34877    policy_and_notice    TABLE       CREATE TABLE hr.policy_and_notice (
    uuid text NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    sub_title text NOT NULL,
    url text NOT NULL,
    created_at text NOT NULL,
    updated_at text,
    status integer NOT NULL,
    remarks text,
    created_by text
);
 !   DROP TABLE hr.policy_and_notice;
       hr         heap    postgres    false    8            �            1259    34882    info    TABLE     L  CREATE TABLE lab_dip.info (
    uuid text NOT NULL,
    id integer NOT NULL,
    name text NOT NULL,
    order_info_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    lab_status integer DEFAULT 0,
    thread_order_info_uuid text
);
    DROP TABLE lab_dip.info;
       lab_dip         heap    postgres    false    9            �            1259    34888    info_id_seq    SEQUENCE     �   CREATE SEQUENCE lab_dip.info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE lab_dip.info_id_seq;
       lab_dip          postgres    false    9    252            �           0    0    info_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE lab_dip.info_id_seq OWNED BY lab_dip.info.id;
          lab_dip          postgres    false    253            �            1259    34889    recipe    TABLE     t  CREATE TABLE lab_dip.recipe (
    uuid text NOT NULL,
    id integer NOT NULL,
    lab_dip_info_uuid text,
    name text NOT NULL,
    approved integer DEFAULT 0,
    created_by text,
    status integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    sub_streat text,
    bleaching text
);
    DROP TABLE lab_dip.recipe;
       lab_dip         heap    postgres    false    9            �            1259    34896    recipe_entry    TABLE       CREATE TABLE lab_dip.recipe_entry (
    uuid text NOT NULL,
    recipe_uuid text,
    color text NOT NULL,
    quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    material_uuid text
);
 !   DROP TABLE lab_dip.recipe_entry;
       lab_dip         heap    postgres    false    9                        1259    34901    recipe_id_seq    SEQUENCE     �   CREATE SEQUENCE lab_dip.recipe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE lab_dip.recipe_id_seq;
       lab_dip          postgres    false    9    254            �           0    0    recipe_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE lab_dip.recipe_id_seq OWNED BY lab_dip.recipe.id;
          lab_dip          postgres    false    256                       1259    34902    shade_recipe_sequence    SEQUENCE        CREATE SEQUENCE lab_dip.shade_recipe_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE lab_dip.shade_recipe_sequence;
       lab_dip          postgres    false    9                       1259    34903    shade_recipe    TABLE     }  CREATE TABLE lab_dip.shade_recipe (
    uuid text NOT NULL,
    id integer DEFAULT nextval('lab_dip.shade_recipe_sequence'::regclass) NOT NULL,
    name text NOT NULL,
    sub_streat text,
    lab_status integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    bleaching text
);
 !   DROP TABLE lab_dip.shade_recipe;
       lab_dip         heap    postgres    false    257    9                       1259    34910    shade_recipe_entry    TABLE       CREATE TABLE lab_dip.shade_recipe_entry (
    uuid text NOT NULL,
    shade_recipe_uuid text,
    material_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 '   DROP TABLE lab_dip.shade_recipe_entry;
       lab_dip         heap    postgres    false    9                       1259    34915    info    TABLE     u  CREATE TABLE material.info (
    uuid text NOT NULL,
    section_uuid text,
    type_uuid text,
    name text NOT NULL,
    short_name text,
    unit text NOT NULL,
    threshold numeric(20,4) DEFAULT 0 NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    created_by text
);
    DROP TABLE material.info;
       material         heap    postgres    false    10                       1259    34921    section    TABLE     �   CREATE TABLE material.section (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE material.section;
       material         heap    postgres    false    10                       1259    34926    stock    TABLE     �  CREATE TABLE material.stock (
    uuid text NOT NULL,
    material_uuid text,
    stock numeric(20,4) DEFAULT 0 NOT NULL,
    tape_making numeric(20,4) DEFAULT 0 NOT NULL,
    coil_forming numeric(20,4) DEFAULT 0 NOT NULL,
    dying_and_iron numeric(20,4) DEFAULT 0 NOT NULL,
    m_gapping numeric(20,4) DEFAULT 0 NOT NULL,
    v_gapping numeric(20,4) DEFAULT 0 NOT NULL,
    v_teeth_molding numeric(20,4) DEFAULT 0 NOT NULL,
    m_teeth_molding numeric(20,4) DEFAULT 0 NOT NULL,
    teeth_assembling_and_polishing numeric(20,4) DEFAULT 0 NOT NULL,
    m_teeth_cleaning numeric(20,4) DEFAULT 0 NOT NULL,
    v_teeth_cleaning numeric(20,4) DEFAULT 0 NOT NULL,
    plating_and_iron numeric(20,4) DEFAULT 0 NOT NULL,
    m_sealing numeric(20,4) DEFAULT 0 NOT NULL,
    v_sealing numeric(20,4) DEFAULT 0 NOT NULL,
    n_t_cutting numeric(20,4) DEFAULT 0 NOT NULL,
    v_t_cutting numeric(20,4) DEFAULT 0 NOT NULL,
    m_stopper numeric(20,4) DEFAULT 0 NOT NULL,
    v_stopper numeric(20,4) DEFAULT 0 NOT NULL,
    n_stopper numeric(20,4) DEFAULT 0 NOT NULL,
    cutting numeric(20,4) DEFAULT 0 NOT NULL,
    die_casting numeric(20,4) DEFAULT 0 NOT NULL,
    slider_assembly numeric(20,4) DEFAULT 0 NOT NULL,
    coloring numeric(20,4) DEFAULT 0 NOT NULL,
    remarks text,
    lab_dip numeric(20,4) DEFAULT 0,
    m_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL,
    v_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL,
    n_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL,
    s_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE material.stock;
       material         heap    postgres    false    10                       1259    34959    stock_to_sfg    TABLE     =  CREATE TABLE material.stock_to_sfg (
    uuid text NOT NULL,
    material_uuid text,
    order_entry_uuid text,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 "   DROP TABLE material.stock_to_sfg;
       material         heap    postgres    false    10                       1259    34964    trx    TABLE       CREATE TABLE material.trx (
    uuid text NOT NULL,
    material_uuid text,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE material.trx;
       material         heap    postgres    false    10            	           1259    34969    type    TABLE     �   CREATE TABLE material.type (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE material.type;
       material         heap    postgres    false    10            
           1259    34974    used    TABLE     J  CREATE TABLE material.used (
    uuid text NOT NULL,
    material_uuid text,
    section text NOT NULL,
    used_quantity numeric(20,4) NOT NULL,
    wastage numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE material.used;
       material         heap    postgres    false    10                       1259    34980    machine    TABLE     1  CREATE TABLE public.machine (
    uuid text NOT NULL,
    name text NOT NULL,
    is_vislon integer DEFAULT 0,
    is_metal integer DEFAULT 0,
    is_nylon integer DEFAULT 0,
    is_sewing_thread integer DEFAULT 0,
    is_bulk integer DEFAULT 0,
    is_sample integer DEFAULT 0,
    min_capacity numeric(20,4) NOT NULL,
    max_capacity numeric(20,4) NOT NULL,
    water_capacity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE public.machine;
       public         heap    postgres    false    15                       1259    34992    section    TABLE     w   CREATE TABLE public.section (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text
);
    DROP TABLE public.section;
       public         heap    postgres    false    15                       1259    34997    purchase_description_sequence    SEQUENCE     �   CREATE SEQUENCE purchase.purchase_description_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE purchase.purchase_description_sequence;
       purchase          postgres    false    11                       1259    34998    description    TABLE     �  CREATE TABLE purchase.description (
    uuid text NOT NULL,
    vendor_uuid text,
    is_local integer NOT NULL,
    lc_number text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    id integer DEFAULT nextval('purchase.purchase_description_sequence'::regclass) NOT NULL,
    challan_number text
);
 !   DROP TABLE purchase.description;
       purchase         heap    postgres    false    269    11                       1259    35004    entry    TABLE     ;  CREATE TABLE purchase.entry (
    uuid text NOT NULL,
    purchase_description_uuid text,
    material_uuid text,
    quantity numeric(20,4) NOT NULL,
    price numeric(20,4) DEFAULT NULL::numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE purchase.entry;
       purchase         heap    postgres    false    11                       1259    35010    vendor    TABLE     M  CREATE TABLE purchase.vendor (
    uuid text NOT NULL,
    name text NOT NULL,
    contact_name text NOT NULL,
    email text NOT NULL,
    office_address text NOT NULL,
    contact_number text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE purchase.vendor;
       purchase         heap    postgres    false    11                       1259    35015    assembly_stock    TABLE     �  CREATE TABLE slider.assembly_stock (
    uuid text NOT NULL,
    name text NOT NULL,
    die_casting_body_uuid text,
    die_casting_puller_uuid text,
    die_casting_cap_uuid text,
    die_casting_link_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 "   DROP TABLE slider.assembly_stock;
       slider         heap    postgres    false    12                       1259    35022    coloring_transaction    TABLE     R  CREATE TABLE slider.coloring_transaction (
    uuid text NOT NULL,
    stock_uuid text,
    order_info_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 (   DROP TABLE slider.coloring_transaction;
       slider         heap    postgres    false    12                       1259    35028    die_casting    TABLE     T  CREATE TABLE slider.die_casting (
    uuid text NOT NULL,
    name text NOT NULL,
    item text,
    zipper_number text,
    end_type text,
    puller_type text,
    logo_type text,
    slider_body_shape text,
    slider_link text,
    quantity numeric(20,4) DEFAULT 0,
    weight numeric(20,4) DEFAULT 0,
    pcs_per_kg numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    quantity_in_sa numeric(20,4) DEFAULT 0,
    is_logo_body integer DEFAULT 0,
    is_logo_puller integer DEFAULT 0,
    type text
);
    DROP TABLE slider.die_casting;
       slider         heap    postgres    false    12                       1259    35039    die_casting_production    TABLE     �  CREATE TABLE slider.die_casting_production (
    uuid text NOT NULL,
    die_casting_uuid text,
    mc_no integer NOT NULL,
    cavity_goods integer NOT NULL,
    cavity_defect integer NOT NULL,
    push integer NOT NULL,
    weight numeric(20,4) NOT NULL,
    order_description_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 *   DROP TABLE slider.die_casting_production;
       slider         heap    postgres    false    12                       1259    35044    die_casting_to_assembly_stock    TABLE     �  CREATE TABLE slider.die_casting_to_assembly_stock (
    uuid text NOT NULL,
    assembly_stock_uuid text,
    production_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    wastage numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    with_link integer DEFAULT 1,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 1   DROP TABLE slider.die_casting_to_assembly_stock;
       slider         heap    postgres    false    12                       1259    35053    die_casting_transaction    TABLE     V  CREATE TABLE slider.die_casting_transaction (
    uuid text NOT NULL,
    die_casting_uuid text,
    stock_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 +   DROP TABLE slider.die_casting_transaction;
       slider         heap    postgres    false    12                       1259    35059 
   production    TABLE     �  CREATE TABLE slider.production (
    uuid text NOT NULL,
    stock_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    wastage numeric(20,4) NOT NULL,
    section text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    with_link integer DEFAULT 1,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE slider.production;
       slider         heap    postgres    false    12                       1259    35066    transaction    TABLE     �  CREATE TABLE slider.transaction (
    uuid text NOT NULL,
    stock_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    from_section text NOT NULL,
    to_section text NOT NULL,
    assembly_stock_uuid text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE slider.transaction;
       slider         heap    postgres    false    12                       1259    35072    trx_against_stock    TABLE     7  CREATE TABLE slider.trx_against_stock (
    uuid text NOT NULL,
    die_casting_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 %   DROP TABLE slider.trx_against_stock;
       slider         heap    postgres    false    12                       1259    35078    thread_batch_sequence    SEQUENCE     ~   CREATE SEQUENCE thread.thread_batch_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE thread.thread_batch_sequence;
       thread          postgres    false    13                       1259    35079    batch    TABLE     �  CREATE TABLE thread.batch (
    uuid text NOT NULL,
    id integer DEFAULT nextval('thread.thread_batch_sequence'::regclass) NOT NULL,
    dyeing_operator text,
    reason text,
    category text,
    status text,
    pass_by text,
    shift text,
    dyeing_supervisor text,
    coning_operator text,
    coning_supervisor text,
    coning_machines text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    yarn_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    machine_uuid text,
    lab_created_by text,
    lab_created_at timestamp without time zone,
    lab_updated_at timestamp without time zone,
    yarn_issue_created_by text,
    yarn_issue_created_at timestamp without time zone,
    yarn_issue_updated_at timestamp without time zone,
    is_drying_complete text,
    drying_created_at timestamp without time zone,
    drying_updated_at timestamp without time zone,
    dyeing_created_by text,
    dyeing_created_at timestamp without time zone,
    dyeing_updated_at timestamp without time zone,
    coning_created_by text,
    coning_created_at timestamp without time zone,
    coning_updated_at timestamp without time zone,
    slot integer DEFAULT 0
);
    DROP TABLE thread.batch;
       thread         heap    postgres    false    282    13                       1259    35087    batch_entry    TABLE     Z  CREATE TABLE thread.batch_entry (
    uuid text NOT NULL,
    batch_uuid text,
    order_entry_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    coning_production_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    coning_carton_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    coning_created_at timestamp without time zone,
    coning_updated_at timestamp without time zone,
    transfer_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    transfer_carton_quantity integer DEFAULT 0
);
    DROP TABLE thread.batch_entry;
       thread         heap    postgres    false    13                       1259    35097    batch_entry_production    TABLE     M  CREATE TABLE thread.batch_entry_production (
    uuid text NOT NULL,
    batch_entry_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    coning_carton_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 *   DROP TABLE thread.batch_entry_production;
       thread         heap    postgres    false    13                       1259    35102    batch_entry_trx    TABLE     /  CREATE TABLE thread.batch_entry_trx (
    uuid text NOT NULL,
    batch_entry_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    carton_quantity integer DEFAULT 0
);
 #   DROP TABLE thread.batch_entry_trx;
       thread         heap    postgres    false    13                       1259    35108    challan    TABLE     U  CREATE TABLE thread.challan (
    uuid text NOT NULL,
    order_info_uuid text,
    carton_quantity integer NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    assign_to text,
    gate_pass integer DEFAULT 0,
    received integer DEFAULT 0
);
    DROP TABLE thread.challan;
       thread         heap    postgres    false    13                        1259    35115    challan_entry    TABLE     �  CREATE TABLE thread.challan_entry (
    uuid text NOT NULL,
    challan_uuid text,
    order_entry_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    carton_quantity integer NOT NULL,
    short_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    reject_quantity numeric(20,4) DEFAULT 0 NOT NULL
);
 !   DROP TABLE thread.challan_entry;
       thread         heap    postgres    false    13            !           1259    35122    count_length    TABLE     �  CREATE TABLE thread.count_length (
    uuid text NOT NULL,
    count text NOT NULL,
    sst text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    min_weight numeric(20,4),
    max_weight numeric(20,4),
    length numeric NOT NULL,
    price numeric(20,4) NOT NULL,
    cone_per_carton integer DEFAULT 0 NOT NULL
);
     DROP TABLE thread.count_length;
       thread         heap    postgres    false    13            "           1259    35128    dyes_category    TABLE     B  CREATE TABLE thread.dyes_category (
    uuid text NOT NULL,
    name text NOT NULL,
    upto_percentage numeric(20,4) DEFAULT 0 NOT NULL,
    bleaching text,
    id integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 !   DROP TABLE thread.dyes_category;
       thread         heap    postgres    false    13            #           1259    35135    order_entry    TABLE        CREATE TABLE thread.order_entry (
    uuid text NOT NULL,
    order_info_uuid text,
    lab_reference text,
    color text NOT NULL,
    po text,
    style text,
    count_length_uuid text,
    quantity numeric(20,4) NOT NULL,
    company_price numeric(20,4) DEFAULT 0 NOT NULL,
    party_price numeric(20,4) DEFAULT 0 NOT NULL,
    swatch_approval_date timestamp without time zone,
    production_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    bleaching text,
    transfer_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    recipe_uuid text,
    pi numeric(20,4) DEFAULT 0 NOT NULL,
    delivered numeric(20,4) DEFAULT 0 NOT NULL,
    warehouse numeric(20,4) DEFAULT 0 NOT NULL,
    short_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    reject_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    production_quantity_in_kg numeric(20,4) DEFAULT 0 NOT NULL,
    carton_quantity integer DEFAULT 0
);
    DROP TABLE thread.order_entry;
       thread         heap    postgres    false    13            $           1259    35151    thread_order_info_sequence    SEQUENCE     �   CREATE SEQUENCE thread.thread_order_info_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE thread.thread_order_info_sequence;
       thread          postgres    false    13            %           1259    35152 
   order_info    TABLE       CREATE TABLE thread.order_info (
    uuid text NOT NULL,
    id integer DEFAULT nextval('thread.thread_order_info_sequence'::regclass) NOT NULL,
    party_uuid text,
    marketing_uuid text,
    factory_uuid text,
    merchandiser_uuid text,
    buyer_uuid text,
    is_sample integer DEFAULT 0,
    is_bill integer DEFAULT 0,
    delivery_date timestamp without time zone,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    is_cash integer DEFAULT 0
);
    DROP TABLE thread.order_info;
       thread         heap    postgres    false    292    13            &           1259    35161    programs    TABLE     %  CREATE TABLE thread.programs (
    uuid text NOT NULL,
    dyes_category_uuid text,
    material_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE thread.programs;
       thread         heap    postgres    false    13            '           1259    35167    batch    TABLE     w  CREATE TABLE zipper.batch (
    uuid text NOT NULL,
    id integer NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    batch_status zipper.batch_status DEFAULT 'pending'::zipper.batch_status,
    machine_uuid text,
    slot integer DEFAULT 0,
    received integer DEFAULT 0
);
    DROP TABLE zipper.batch;
       zipper         heap    postgres    false    1013    1013    14            (           1259    35175    batch_entry    TABLE     n  CREATE TABLE zipper.batch_entry (
    uuid text NOT NULL,
    batch_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    production_quantity numeric(20,4) DEFAULT 0,
    production_quantity_in_kg numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    sfg_uuid text
);
    DROP TABLE zipper.batch_entry;
       zipper         heap    postgres    false    14            )           1259    35183    batch_id_seq    SEQUENCE     �   CREATE SEQUENCE zipper.batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE zipper.batch_id_seq;
       zipper          postgres    false    295    14            �           0    0    batch_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE zipper.batch_id_seq OWNED BY zipper.batch.id;
          zipper          postgres    false    297            *           1259    35184    batch_production    TABLE     J  CREATE TABLE zipper.batch_production (
    uuid text NOT NULL,
    batch_entry_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    production_quantity_in_kg numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 $   DROP TABLE zipper.batch_production;
       zipper         heap    postgres    false    14            +           1259    35189    dyed_tape_transaction    TABLE     )  CREATE TABLE zipper.dyed_tape_transaction (
    uuid text NOT NULL,
    order_description_uuid text,
    colors text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 )   DROP TABLE zipper.dyed_tape_transaction;
       zipper         heap    postgres    false    14            ,           1259    35194     dyed_tape_transaction_from_stock    TABLE     F  CREATE TABLE zipper.dyed_tape_transaction_from_stock (
    uuid text NOT NULL,
    order_description_uuid text,
    trx_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    tape_coil_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 4   DROP TABLE zipper.dyed_tape_transaction_from_stock;
       zipper         heap    postgres    false    14            -           1259    35200    dying_batch    TABLE     �   CREATE TABLE zipper.dying_batch (
    uuid text NOT NULL,
    id integer NOT NULL,
    mc_no integer NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE zipper.dying_batch;
       zipper         heap    postgres    false    14            .           1259    35205    dying_batch_entry    TABLE     v  CREATE TABLE zipper.dying_batch_entry (
    uuid text NOT NULL,
    dying_batch_uuid text,
    batch_entry_uuid text,
    quantity numeric(20,4) NOT NULL,
    production_quantity numeric(20,4) NOT NULL,
    production_quantity_in_kg numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 %   DROP TABLE zipper.dying_batch_entry;
       zipper         heap    postgres    false    14            /           1259    35210    dying_batch_id_seq    SEQUENCE     �   CREATE SEQUENCE zipper.dying_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE zipper.dying_batch_id_seq;
       zipper          postgres    false    301    14            �           0    0    dying_batch_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE zipper.dying_batch_id_seq OWNED BY zipper.dying_batch.id;
          zipper          postgres    false    303            0           1259    35211 &   material_trx_against_order_description    TABLE     [  CREATE TABLE zipper.material_trx_against_order_description (
    uuid text NOT NULL,
    order_description_uuid text,
    material_uuid text,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 :   DROP TABLE zipper.material_trx_against_order_description;
       zipper         heap    postgres    false    14            1           1259    35216    planning    TABLE     �   CREATE TABLE zipper.planning (
    week text NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE zipper.planning;
       zipper         heap    postgres    false    14            2           1259    35221    planning_entry    TABLE     �  CREATE TABLE zipper.planning_entry (
    uuid text NOT NULL,
    sfg_uuid text,
    sno_quantity numeric(20,4) DEFAULT 0,
    factory_quantity numeric(20,4) DEFAULT 0,
    production_quantity numeric(20,4) DEFAULT 0,
    batch_production_quantity numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    planning_week text,
    sno_remarks text,
    factory_remarks text
);
 "   DROP TABLE zipper.planning_entry;
       zipper         heap    postgres    false    14            3           1259    35230    sfg_production    TABLE     �  CREATE TABLE zipper.sfg_production (
    uuid text NOT NULL,
    sfg_uuid text,
    section text NOT NULL,
    production_quantity_in_kg numeric(20,4) DEFAULT 0,
    production_quantity numeric(20,4) DEFAULT 0,
    wastage numeric(20,4) DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 "   DROP TABLE zipper.sfg_production;
       zipper         heap    postgres    false    14            4           1259    35238    sfg_transaction    TABLE     �  CREATE TABLE zipper.sfg_transaction (
    uuid text NOT NULL,
    trx_from text NOT NULL,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) DEFAULT 0,
    slider_item_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    sfg_uuid text,
    trx_quantity_in_kg numeric(20,4) DEFAULT 0 NOT NULL
);
 #   DROP TABLE zipper.sfg_transaction;
       zipper         heap    postgres    false    14            5           1259    35245    tape_coil_production    TABLE     _  CREATE TABLE zipper.tape_coil_production (
    uuid text NOT NULL,
    section text NOT NULL,
    tape_coil_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    wastage numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 (   DROP TABLE zipper.tape_coil_production;
       zipper         heap    postgres    false    14            6           1259    35251    tape_coil_required    TABLE     t  CREATE TABLE zipper.tape_coil_required (
    uuid text NOT NULL,
    end_type_uuid text,
    item_uuid text,
    nylon_stopper_uuid text,
    zipper_number_uuid text,
    top numeric(20,4) NOT NULL,
    bottom numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 &   DROP TABLE zipper.tape_coil_required;
       zipper         heap    postgres    false    14            7           1259    35256    tape_coil_to_dyeing    TABLE     /  CREATE TABLE zipper.tape_coil_to_dyeing (
    uuid text NOT NULL,
    tape_coil_uuid text,
    order_description_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 '   DROP TABLE zipper.tape_coil_to_dyeing;
       zipper         heap    postgres    false    14            8           1259    35261    tape_trx    TABLE       CREATE TABLE zipper.tape_trx (
    uuid text NOT NULL,
    tape_coil_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    to_section text
);
    DROP TABLE zipper.tape_trx;
       zipper         heap    postgres    false    14            9           1259    35266    v_order_details    VIEW     Y	  CREATE VIEW zipper.v_order_details AS
 SELECT order_info.uuid AS order_info_uuid,
    order_info.reference_order_info_uuid,
    concat('Z', to_char(order_info.created_at, 'YY'::text), '-', lpad((order_info.id)::text, 4, '0'::text)) AS order_number,
    concat(op_item.short_name, op_nylon_stopper.short_name, '-', op_zipper.short_name, '-', op_end.short_name, '-', op_puller.short_name) AS item_description,
    op_item.name AS item_name,
    op_nylon_stopper.name AS nylon_stopper_name,
    op_zipper.name AS zipper_number_name,
    op_end.name AS end_type_name,
    op_puller.name AS puller_type_name,
    order_description.uuid AS order_description_uuid,
    order_info.buyer_uuid,
    buyer.name AS buyer_name,
    order_info.party_uuid,
    party.name AS party_name,
    order_info.marketing_uuid,
    marketing.name AS marketing_name,
    order_info.merchandiser_uuid,
    merchandiser.name AS merchandiser_name,
    order_info.factory_uuid,
    factory.name AS factory_name,
    order_info.is_sample,
    order_info.is_bill,
    order_info.is_cash,
    order_info.marketing_priority,
    order_info.factory_priority,
    order_info.status,
    order_info.created_by AS created_by_uuid,
    users.name AS created_by_name,
    order_info.created_at,
    order_info.updated_at,
    order_info.remarks
   FROM ((((((((((((zipper.order_info
     LEFT JOIN zipper.order_description ON ((order_description.order_info_uuid = order_info.uuid)))
     LEFT JOIN public.marketing ON ((marketing.uuid = order_info.marketing_uuid)))
     LEFT JOIN public.buyer ON ((buyer.uuid = order_info.buyer_uuid)))
     LEFT JOIN public.merchandiser ON ((merchandiser.uuid = order_info.merchandiser_uuid)))
     LEFT JOIN public.factory ON ((factory.uuid = order_info.factory_uuid)))
     LEFT JOIN hr.users ON ((users.uuid = order_info.created_by)))
     LEFT JOIN public.party ON ((party.uuid = order_info.party_uuid)))
     LEFT JOIN public.properties op_item ON ((op_item.uuid = order_description.item)))
     LEFT JOIN public.properties op_zipper ON ((op_zipper.uuid = order_description.zipper_number)))
     LEFT JOIN public.properties op_end ON ((op_end.uuid = order_description.end_type)))
     LEFT JOIN public.properties op_puller ON ((op_puller.uuid = order_description.puller_type)))
     LEFT JOIN public.properties op_nylon_stopper ON ((op_nylon_stopper.uuid = order_description.nylon_stopper)));
 "   DROP VIEW zipper.v_order_details;
       zipper          postgres    false    242    234    242    242    234    242    242    242    242    242    242    242    242    242    242    242    242    242    242    242    239    239    239    239    239    239    239    237    237    237    236    231    231    232    232    236    235    235    233    233    14            h           2604    35271    migrations_details id    DEFAULT     �   ALTER TABLE ONLY drizzle.migrations_details ALTER COLUMN id SET DEFAULT nextval('drizzle.migrations_details_id_seq'::regclass);
 E   ALTER TABLE drizzle.migrations_details ALTER COLUMN id DROP DEFAULT;
       drizzle          postgres    false    248    247            i           2604    35272    info id    DEFAULT     d   ALTER TABLE ONLY lab_dip.info ALTER COLUMN id SET DEFAULT nextval('lab_dip.info_id_seq'::regclass);
 7   ALTER TABLE lab_dip.info ALTER COLUMN id DROP DEFAULT;
       lab_dip          postgres    false    253    252            k           2604    35273 	   recipe id    DEFAULT     h   ALTER TABLE ONLY lab_dip.recipe ALTER COLUMN id SET DEFAULT nextval('lab_dip.recipe_id_seq'::regclass);
 9   ALTER TABLE lab_dip.recipe ALTER COLUMN id DROP DEFAULT;
       lab_dip          postgres    false    256    254            �           2604    35274    batch id    DEFAULT     d   ALTER TABLE ONLY zipper.batch ALTER COLUMN id SET DEFAULT nextval('zipper.batch_id_seq'::regclass);
 7   ALTER TABLE zipper.batch ALTER COLUMN id DROP DEFAULT;
       zipper          postgres    false    297    295            �           2604    35275    dying_batch id    DEFAULT     p   ALTER TABLE ONLY zipper.dying_batch ALTER COLUMN id SET DEFAULT nextval('zipper.dying_batch_id_seq'::regclass);
 =   ALTER TABLE zipper.dying_batch ALTER COLUMN id DROP DEFAULT;
       zipper          postgres    false    303    301            /          0    34666    bank 
   TABLE DATA           �   COPY commercial.bank (uuid, name, swift_code, address, policy, created_at, updated_at, remarks, created_by, routing_no) FROM stdin;
 
   commercial          postgres    false    219   �      1          0    34672    lc 
   TABLE DATA           �  COPY commercial.lc (uuid, party_uuid, lc_number, lc_date, payment_value, payment_date, ldbc_fdbc, acceptance_date, maturity_date, commercial_executive, party_bank, production_complete, lc_cancel, handover_date, shipment_date, expiry_date, ud_no, ud_received, at_sight, amd_date, amd_count, problematical, epz, created_by, created_at, updated_at, remarks, id, document_receive_date, is_rtgs) FROM stdin;
 
   commercial          postgres    false    221   �      3          0    34686    pi_cash 
   TABLE DATA             COPY commercial.pi_cash (uuid, id, lc_uuid, order_info_uuids, marketing_uuid, party_uuid, merchandiser_uuid, factory_uuid, bank_uuid, validity, payment, is_pi, conversion_rate, receive_amount, created_by, created_at, updated_at, remarks, weight, thread_order_info_uuids) FROM stdin;
 
   commercial          postgres    false    223         4          0    34698    pi_cash_entry 
   TABLE DATA           �   COPY commercial.pi_cash_entry (uuid, pi_cash_uuid, sfg_uuid, pi_cash_quantity, created_at, updated_at, remarks, thread_order_entry_uuid) FROM stdin;
 
   commercial          postgres    false    224   4      6          0    34704    challan 
   TABLE DATA           �   COPY delivery.challan (uuid, carton_quantity, assign_to, receive_status, created_by, created_at, updated_at, remarks, id, gate_pass, order_info_uuid) FROM stdin;
    delivery          postgres    false    226   Q      7          0    34712    challan_entry 
   TABLE DATA           q   COPY delivery.challan_entry (uuid, challan_uuid, packing_list_uuid, created_at, updated_at, remarks) FROM stdin;
    delivery          postgres    false    227   n      9          0    34718    packing_list 
   TABLE DATA           �   COPY delivery.packing_list (uuid, carton_size, carton_weight, created_by, created_at, updated_at, remarks, order_info_uuid, id, challan_uuid) FROM stdin;
    delivery          postgres    false    229   �      :          0    34724    packing_list_entry 
   TABLE DATA           �   COPY delivery.packing_list_entry (uuid, packing_list_uuid, sfg_uuid, quantity, created_at, updated_at, remarks, short_quantity, reject_quantity) FROM stdin;
    delivery          postgres    false    230   �      I          0    34861    migrations_details 
   TABLE DATA           C   COPY drizzle.migrations_details (id, hash, created_at) FROM stdin;
    drizzle          postgres    false    247   �      K          0    34867 
   department 
   TABLE DATA           S   COPY hr.department (uuid, department, created_at, updated_at, remarks) FROM stdin;
    hr          postgres    false    249   +6      L          0    34872    designation 
   TABLE DATA           U   COPY hr.designation (uuid, designation, created_at, updated_at, remarks) FROM stdin;
    hr          postgres    false    250   �8      M          0    34877    policy_and_notice 
   TABLE DATA              COPY hr.policy_and_notice (uuid, type, title, sub_title, url, created_at, updated_at, status, remarks, created_by) FROM stdin;
    hr          postgres    false    251   <      ;          0    34731    users 
   TABLE DATA           �   COPY hr.users (uuid, name, email, pass, designation_uuid, can_access, ext, phone, created_at, updated_at, status, remarks, department_uuid) FROM stdin;
    hr          postgres    false    231   6<      N          0    34882    info 
   TABLE DATA           �   COPY lab_dip.info (uuid, id, name, order_info_uuid, created_by, created_at, updated_at, remarks, lab_status, thread_order_info_uuid) FROM stdin;
    lab_dip          postgres    false    252   �U      P          0    34889    recipe 
   TABLE DATA           �   COPY lab_dip.recipe (uuid, id, lab_dip_info_uuid, name, approved, created_by, status, created_at, updated_at, remarks, sub_streat, bleaching) FROM stdin;
    lab_dip          postgres    false    254   �U      Q          0    34896    recipe_entry 
   TABLE DATA           {   COPY lab_dip.recipe_entry (uuid, recipe_uuid, color, quantity, created_at, updated_at, remarks, material_uuid) FROM stdin;
    lab_dip          postgres    false    255   �U      T          0    34903    shade_recipe 
   TABLE DATA           �   COPY lab_dip.shade_recipe (uuid, id, name, sub_streat, lab_status, created_by, created_at, updated_at, remarks, bleaching) FROM stdin;
    lab_dip          postgres    false    258   V      U          0    34910    shade_recipe_entry 
   TABLE DATA           �   COPY lab_dip.shade_recipe_entry (uuid, shade_recipe_uuid, material_uuid, quantity, created_at, updated_at, remarks) FROM stdin;
    lab_dip          postgres    false    259   ,V      V          0    34915    info 
   TABLE DATA           �   COPY material.info (uuid, section_uuid, type_uuid, name, short_name, unit, threshold, description, created_at, updated_at, remarks, created_by) FROM stdin;
    material          postgres    false    260   IV      W          0    34921    section 
   TABLE DATA           h   COPY material.section (uuid, name, short_name, remarks, created_at, updated_at, created_by) FROM stdin;
    material          postgres    false    261   �Y      X          0    34926    stock 
   TABLE DATA           �  COPY material.stock (uuid, material_uuid, stock, tape_making, coil_forming, dying_and_iron, m_gapping, v_gapping, v_teeth_molding, m_teeth_molding, teeth_assembling_and_polishing, m_teeth_cleaning, v_teeth_cleaning, plating_and_iron, m_sealing, v_sealing, n_t_cutting, v_t_cutting, m_stopper, v_stopper, n_stopper, cutting, die_casting, slider_assembly, coloring, remarks, lab_dip, m_qc_and_packing, v_qc_and_packing, n_qc_and_packing, s_qc_and_packing) FROM stdin;
    material          postgres    false    262   �Z      Y          0    34959    stock_to_sfg 
   TABLE DATA           �   COPY material.stock_to_sfg (uuid, material_uuid, order_entry_uuid, trx_to, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    material          postgres    false    263   X\      Z          0    34964    trx 
   TABLE DATA           w   COPY material.trx (uuid, material_uuid, trx_to, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    material          postgres    false    264   u\      [          0    34969    type 
   TABLE DATA           e   COPY material.type (uuid, name, short_name, remarks, created_at, updated_at, created_by) FROM stdin;
    material          postgres    false    265   �\      \          0    34974    used 
   TABLE DATA           �   COPY material.used (uuid, material_uuid, section, used_quantity, wastage, created_by, created_at, updated_at, remarks) FROM stdin;
    material          postgres    false    266   F]      <          0    34737    buyer 
   TABLE DATA           d   COPY public.buyer (uuid, name, short_name, remarks, created_at, updated_at, created_by) FROM stdin;
    public          postgres    false    232   c]      =          0    34742    factory 
   TABLE DATA           v   COPY public.factory (uuid, party_uuid, name, phone, address, created_at, updated_at, created_by, remarks) FROM stdin;
    public          postgres    false    233   	�      ]          0    34980    machine 
   TABLE DATA           �   COPY public.machine (uuid, name, is_vislon, is_metal, is_nylon, is_sewing_thread, is_bulk, is_sample, min_capacity, max_capacity, water_capacity, created_by, created_at, updated_at, remarks) FROM stdin;
    public          postgres    false    267   �      >          0    34747 	   marketing 
   TABLE DATA           s   COPY public.marketing (uuid, name, short_name, user_uuid, remarks, created_at, updated_at, created_by) FROM stdin;
    public          postgres    false    234   ��      ?          0    34752    merchandiser 
   TABLE DATA           �   COPY public.merchandiser (uuid, party_uuid, name, email, phone, address, created_at, updated_at, created_by, remarks) FROM stdin;
    public          postgres    false    235   .�      @          0    34757    party 
   TABLE DATA           m   COPY public.party (uuid, name, short_name, remarks, created_at, updated_at, created_by, address) FROM stdin;
    public          postgres    false    236   �-      A          0    34762 
   properties 
   TABLE DATA           y   COPY public.properties (uuid, item_for, type, name, short_name, created_by, created_at, updated_at, remarks) FROM stdin;
    public          postgres    false    237   �a      ^          0    34992    section 
   TABLE DATA           B   COPY public.section (uuid, name, short_name, remarks) FROM stdin;
    public          postgres    false    268   2p      `          0    34998    description 
   TABLE DATA           �   COPY purchase.description (uuid, vendor_uuid, is_local, lc_number, created_by, created_at, updated_at, remarks, id, challan_number) FROM stdin;
    purchase          postgres    false    270   Op      a          0    35004    entry 
   TABLE DATA           �   COPY purchase.entry (uuid, purchase_description_uuid, material_uuid, quantity, price, created_at, updated_at, remarks) FROM stdin;
    purchase          postgres    false    271   lp      b          0    35010    vendor 
   TABLE DATA           �   COPY purchase.vendor (uuid, name, contact_name, email, office_address, contact_number, remarks, created_at, updated_at, created_by) FROM stdin;
    purchase          postgres    false    272   �p      c          0    35015    assembly_stock 
   TABLE DATA           �   COPY slider.assembly_stock (uuid, name, die_casting_body_uuid, die_casting_puller_uuid, die_casting_cap_uuid, die_casting_link_uuid, quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    273   �q      d          0    35022    coloring_transaction 
   TABLE DATA           �   COPY slider.coloring_transaction (uuid, stock_uuid, order_info_uuid, trx_quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    274   �q      e          0    35028    die_casting 
   TABLE DATA           �   COPY slider.die_casting (uuid, name, item, zipper_number, end_type, puller_type, logo_type, slider_body_shape, slider_link, quantity, weight, pcs_per_kg, created_at, updated_at, remarks, quantity_in_sa, is_logo_body, is_logo_puller, type) FROM stdin;
    slider          postgres    false    275   r      f          0    35039    die_casting_production 
   TABLE DATA           �   COPY slider.die_casting_production (uuid, die_casting_uuid, mc_no, cavity_goods, cavity_defect, push, weight, order_description_uuid, created_by, created_at, updated_at, remarks) FROM stdin;
    slider          postgres    false    276   ,r      g          0    35044    die_casting_to_assembly_stock 
   TABLE DATA           �   COPY slider.die_casting_to_assembly_stock (uuid, assembly_stock_uuid, production_quantity, wastage, created_by, created_at, updated_at, remarks, with_link, weight) FROM stdin;
    slider          postgres    false    277   Ir      h          0    35053    die_casting_transaction 
   TABLE DATA           �   COPY slider.die_casting_transaction (uuid, die_casting_uuid, stock_uuid, trx_quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    278   fr      i          0    35059 
   production 
   TABLE DATA           �   COPY slider.production (uuid, stock_uuid, production_quantity, wastage, section, created_by, created_at, updated_at, remarks, with_link, weight) FROM stdin;
    slider          postgres    false    279   �r      B          0    34767    stock 
   TABLE DATA           Q  COPY slider.stock (uuid, order_quantity, body_quantity, cap_quantity, puller_quantity, link_quantity, sa_prod, coloring_stock, coloring_prod, trx_to_finishing, u_top_quantity, h_bottom_quantity, box_pin_quantity, two_way_pin_quantity, created_at, updated_at, remarks, quantity_in_sa, order_description_uuid, finishing_stock) FROM stdin;
    slider          postgres    false    238   �r      j          0    35066    transaction 
   TABLE DATA           �   COPY slider.transaction (uuid, stock_uuid, trx_quantity, created_by, created_at, updated_at, remarks, from_section, to_section, assembly_stock_uuid, weight) FROM stdin;
    slider          postgres    false    280   �s      k          0    35072    trx_against_stock 
   TABLE DATA           �   COPY slider.trx_against_stock (uuid, die_casting_uuid, quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    281   �s      m          0    35079    batch 
   TABLE DATA             COPY thread.batch (uuid, id, dyeing_operator, reason, category, status, pass_by, shift, dyeing_supervisor, coning_operator, coning_supervisor, coning_machines, created_by, created_at, updated_at, remarks, yarn_quantity, machine_uuid, lab_created_by, lab_created_at, lab_updated_at, yarn_issue_created_by, yarn_issue_created_at, yarn_issue_updated_at, is_drying_complete, drying_created_at, drying_updated_at, dyeing_created_by, dyeing_created_at, dyeing_updated_at, coning_created_by, coning_created_at, coning_updated_at, slot) FROM stdin;
    thread          postgres    false    283   �s      n          0    35087    batch_entry 
   TABLE DATA           �   COPY thread.batch_entry (uuid, batch_uuid, order_entry_uuid, quantity, coning_production_quantity, coning_carton_quantity, created_at, updated_at, remarks, coning_created_at, coning_updated_at, transfer_quantity, transfer_carton_quantity) FROM stdin;
    thread          postgres    false    284   �s      o          0    35097    batch_entry_production 
   TABLE DATA           �   COPY thread.batch_entry_production (uuid, batch_entry_uuid, production_quantity, coning_carton_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    thread          postgres    false    285    t      p          0    35102    batch_entry_trx 
   TABLE DATA           �   COPY thread.batch_entry_trx (uuid, batch_entry_uuid, quantity, created_by, created_at, updated_at, remarks, carton_quantity) FROM stdin;
    thread          postgres    false    286   t      q          0    35108    challan 
   TABLE DATA           �   COPY thread.challan (uuid, order_info_uuid, carton_quantity, created_by, created_at, updated_at, remarks, assign_to, gate_pass, received) FROM stdin;
    thread          postgres    false    287   :t      r          0    35115    challan_entry 
   TABLE DATA           �   COPY thread.challan_entry (uuid, challan_uuid, order_entry_uuid, quantity, created_by, created_at, updated_at, remarks, carton_quantity, short_quantity, reject_quantity) FROM stdin;
    thread          postgres    false    288   Wt      s          0    35122    count_length 
   TABLE DATA           �   COPY thread.count_length (uuid, count, sst, created_by, created_at, updated_at, remarks, min_weight, max_weight, length, price, cone_per_carton) FROM stdin;
    thread          postgres    false    289   tt      t          0    35128    dyes_category 
   TABLE DATA           �   COPY thread.dyes_category (uuid, name, upto_percentage, bleaching, id, created_by, created_at, updated_at, remarks) FROM stdin;
    thread          postgres    false    290   �u      u          0    35135    order_entry 
   TABLE DATA           �  COPY thread.order_entry (uuid, order_info_uuid, lab_reference, color, po, style, count_length_uuid, quantity, company_price, party_price, swatch_approval_date, production_quantity, created_by, created_at, updated_at, remarks, bleaching, transfer_quantity, recipe_uuid, pi, delivered, warehouse, short_quantity, reject_quantity, production_quantity_in_kg, carton_quantity) FROM stdin;
    thread          postgres    false    291   �u      w          0    35152 
   order_info 
   TABLE DATA           �   COPY thread.order_info (uuid, id, party_uuid, marketing_uuid, factory_uuid, merchandiser_uuid, buyer_uuid, is_sample, is_bill, delivery_date, created_by, created_at, updated_at, remarks, is_cash) FROM stdin;
    thread          postgres    false    293   �u      x          0    35161    programs 
   TABLE DATA           �   COPY thread.programs (uuid, dyes_category_uuid, material_uuid, quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    thread          postgres    false    294   �u      y          0    35167    batch 
   TABLE DATA           �   COPY zipper.batch (uuid, id, created_by, created_at, updated_at, remarks, batch_status, machine_uuid, slot, received) FROM stdin;
    zipper          postgres    false    295   �u      z          0    35175    batch_entry 
   TABLE DATA           �   COPY zipper.batch_entry (uuid, batch_uuid, quantity, production_quantity, production_quantity_in_kg, created_at, updated_at, remarks, sfg_uuid) FROM stdin;
    zipper          postgres    false    296   v      |          0    35184    batch_production 
   TABLE DATA           �   COPY zipper.batch_production (uuid, batch_entry_uuid, production_quantity, production_quantity_in_kg, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    298   1v      }          0    35189    dyed_tape_transaction 
   TABLE DATA           �   COPY zipper.dyed_tape_transaction (uuid, order_description_uuid, colors, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    299   Nv      ~          0    35194     dyed_tape_transaction_from_stock 
   TABLE DATA           �   COPY zipper.dyed_tape_transaction_from_stock (uuid, order_description_uuid, trx_quantity, tape_coil_uuid, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    300   kv                0    35200    dying_batch 
   TABLE DATA           c   COPY zipper.dying_batch (uuid, id, mc_no, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    301   �v      �          0    35205    dying_batch_entry 
   TABLE DATA           �   COPY zipper.dying_batch_entry (uuid, dying_batch_uuid, batch_entry_uuid, quantity, production_quantity, production_quantity_in_kg, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    302   �v      �          0    35211 &   material_trx_against_order_description 
   TABLE DATA           �   COPY zipper.material_trx_against_order_description (uuid, order_description_uuid, material_uuid, trx_to, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    304   �v      C          0    34787    order_description 
   TABLE DATA           J  COPY zipper.order_description (uuid, order_info_uuid, item, zipper_number, end_type, lock_type, puller_type, teeth_color, puller_color, special_requirement, hand, coloring_type, is_slider_provided, slider, slider_starting_section_enum, top_stopper, bottom_stopper, logo_type, is_logo_body, is_logo_puller, description, status, created_at, updated_at, remarks, slider_body_shape, slider_link, end_user, garment, light_preference, garments_wash, created_by, garments_remarks, tape_received, tape_transferred, slider_finishing_stock, nylon_stopper, tape_coil_uuid, teeth_type) FROM stdin;
    zipper          postgres    false    239   �v      D          0    34799    order_entry 
   TABLE DATA           �   COPY zipper.order_entry (uuid, order_description_uuid, style, color, size, quantity, company_price, party_price, status, swatch_status_enum, swatch_approval_date, created_at, updated_at, remarks, bleaching) FROM stdin;
    zipper          postgres    false    240   "z      F          0    34809 
   order_info 
   TABLE DATA           %  COPY zipper.order_info (uuid, id, reference_order_info_uuid, buyer_uuid, party_uuid, marketing_uuid, merchandiser_uuid, factory_uuid, is_sample, is_bill, is_cash, marketing_priority, factory_priority, status, created_by, created_at, updated_at, remarks, conversion_rate, print_in) FROM stdin;
    zipper          postgres    false    242   �}      �          0    35216    planning 
   TABLE DATA           U   COPY zipper.planning (week, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    305   �      �          0    35221    planning_entry 
   TABLE DATA           �   COPY zipper.planning_entry (uuid, sfg_uuid, sno_quantity, factory_quantity, production_quantity, batch_production_quantity, created_at, updated_at, planning_week, sno_remarks, factory_remarks) FROM stdin;
    zipper          postgres    false    306   �      G          0    34821    sfg 
   TABLE DATA             COPY zipper.sfg (uuid, order_entry_uuid, recipe_uuid, dying_and_iron_prod, teeth_molding_stock, teeth_molding_prod, teeth_coloring_stock, teeth_coloring_prod, finishing_stock, finishing_prod, coloring_prod, warehouse, delivered, pi, remarks, short_quantity, reject_quantity) FROM stdin;
    zipper          postgres    false    243   �      �          0    35230    sfg_production 
   TABLE DATA           �   COPY zipper.sfg_production (uuid, sfg_uuid, section, production_quantity_in_kg, production_quantity, wastage, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    307   ��      �          0    35238    sfg_transaction 
   TABLE DATA           �   COPY zipper.sfg_transaction (uuid, trx_from, trx_to, trx_quantity, slider_item_uuid, created_by, created_at, updated_at, remarks, sfg_uuid, trx_quantity_in_kg) FROM stdin;
    zipper          postgres    false    308   Ӂ      H          0    34839 	   tape_coil 
   TABLE DATA             COPY zipper.tape_coil (uuid, quantity, trx_quantity_in_coil, quantity_in_coil, remarks, item_uuid, zipper_number_uuid, name, raw_per_kg_meter, dyed_per_kg_meter, created_by, created_at, updated_at, is_import, is_reverse, trx_quantity_in_dying, stock_quantity) FROM stdin;
    zipper          postgres    false    244   ��      �          0    35245    tape_coil_production 
   TABLE DATA           �   COPY zipper.tape_coil_production (uuid, section, tape_coil_uuid, production_quantity, wastage, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    309   ��      �          0    35251    tape_coil_required 
   TABLE DATA           �   COPY zipper.tape_coil_required (uuid, end_type_uuid, item_uuid, nylon_stopper_uuid, zipper_number_uuid, top, bottom, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    310   �      �          0    35256    tape_coil_to_dyeing 
   TABLE DATA           �   COPY zipper.tape_coil_to_dyeing (uuid, tape_coil_uuid, order_description_uuid, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    311   /�      �          0    35261    tape_trx 
   TABLE DATA              COPY zipper.tape_trx (uuid, tape_coil_uuid, trx_quantity, created_by, created_at, updated_at, remarks, to_section) FROM stdin;
    zipper          postgres    false    312   L�      �           0    0    lc_sequence    SEQUENCE SET     =   SELECT pg_catalog.setval('commercial.lc_sequence', 1, true);
       
   commercial          postgres    false    220            �           0    0    pi_sequence    SEQUENCE SET     =   SELECT pg_catalog.setval('commercial.pi_sequence', 1, true);
       
   commercial          postgres    false    222            �           0    0    challan_sequence    SEQUENCE SET     @   SELECT pg_catalog.setval('delivery.challan_sequence', 1, true);
          delivery          postgres    false    225            �           0    0    packing_list_sequence    SEQUENCE SET     E   SELECT pg_catalog.setval('delivery.packing_list_sequence', 1, true);
          delivery          postgres    false    228            �           0    0    migrations_details_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('drizzle.migrations_details_id_seq', 131, true);
          drizzle          postgres    false    248            �           0    0    info_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('lab_dip.info_id_seq', 1, true);
          lab_dip          postgres    false    253            �           0    0    recipe_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('lab_dip.recipe_id_seq', 1, true);
          lab_dip          postgres    false    256            �           0    0    shade_recipe_sequence    SEQUENCE SET     D   SELECT pg_catalog.setval('lab_dip.shade_recipe_sequence', 1, true);
          lab_dip          postgres    false    257            �           0    0    purchase_description_sequence    SEQUENCE SET     M   SELECT pg_catalog.setval('purchase.purchase_description_sequence', 1, true);
          purchase          postgres    false    269            �           0    0    thread_batch_sequence    SEQUENCE SET     C   SELECT pg_catalog.setval('thread.thread_batch_sequence', 1, true);
          thread          postgres    false    282            �           0    0    thread_order_info_sequence    SEQUENCE SET     H   SELECT pg_catalog.setval('thread.thread_order_info_sequence', 1, true);
          thread          postgres    false    292            �           0    0    batch_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('zipper.batch_id_seq', 1, true);
          zipper          postgres    false    297            �           0    0    dying_batch_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('zipper.dying_batch_id_seq', 1, false);
          zipper          postgres    false    303            �           0    0    order_info_sequence    SEQUENCE SET     A   SELECT pg_catalog.setval('zipper.order_info_sequence', 5, true);
          zipper          postgres    false    241            �           2606    35277    bank bank_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY commercial.bank
    ADD CONSTRAINT bank_pkey PRIMARY KEY (uuid);
 <   ALTER TABLE ONLY commercial.bank DROP CONSTRAINT bank_pkey;
    
   commercial            postgres    false    219            �           2606    35279 
   lc lc_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY commercial.lc
    ADD CONSTRAINT lc_pkey PRIMARY KEY (uuid);
 8   ALTER TABLE ONLY commercial.lc DROP CONSTRAINT lc_pkey;
    
   commercial            postgres    false    221            �           2606    35281     pi_cash_entry pi_cash_entry_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_pkey;
    
   commercial            postgres    false    224            �           2606    35283    pi_cash pi_cash_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_pkey;
    
   commercial            postgres    false    223            �           2606    35285     challan_entry challan_entry_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY delivery.challan_entry
    ADD CONSTRAINT challan_entry_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY delivery.challan_entry DROP CONSTRAINT challan_entry_pkey;
       delivery            postgres    false    227            �           2606    35287    challan challan_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_pkey;
       delivery            postgres    false    226            �           2606    35289 *   packing_list_entry packing_list_entry_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY delivery.packing_list_entry
    ADD CONSTRAINT packing_list_entry_pkey PRIMARY KEY (uuid);
 V   ALTER TABLE ONLY delivery.packing_list_entry DROP CONSTRAINT packing_list_entry_pkey;
       delivery            postgres    false    230            �           2606    35291    packing_list packing_list_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_pkey;
       delivery            postgres    false    229                       2606    35293 *   migrations_details migrations_details_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY drizzle.migrations_details
    ADD CONSTRAINT migrations_details_pkey PRIMARY KEY (id);
 U   ALTER TABLE ONLY drizzle.migrations_details DROP CONSTRAINT migrations_details_pkey;
       drizzle            postgres    false    247                       2606    35295    department department_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY hr.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY hr.department DROP CONSTRAINT department_pkey;
       hr            postgres    false    249                       2606    36526    department department_unique 
   CONSTRAINT     Y   ALTER TABLE ONLY hr.department
    ADD CONSTRAINT department_unique UNIQUE (department);
 B   ALTER TABLE ONLY hr.department DROP CONSTRAINT department_unique;
       hr            postgres    false    249                       2606    35297    designation designation_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY hr.designation
    ADD CONSTRAINT designation_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY hr.designation DROP CONSTRAINT designation_pkey;
       hr            postgres    false    250                       2606    36528    designation designation_unique 
   CONSTRAINT     \   ALTER TABLE ONLY hr.designation
    ADD CONSTRAINT designation_unique UNIQUE (designation);
 D   ALTER TABLE ONLY hr.designation DROP CONSTRAINT designation_unique;
       hr            postgres    false    250                       2606    35299 (   policy_and_notice policy_and_notice_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY hr.policy_and_notice
    ADD CONSTRAINT policy_and_notice_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY hr.policy_and_notice DROP CONSTRAINT policy_and_notice_pkey;
       hr            postgres    false    251            �           2606    35301    users users_email_unique 
   CONSTRAINT     P   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);
 >   ALTER TABLE ONLY hr.users DROP CONSTRAINT users_email_unique;
       hr            postgres    false    231            �           2606    35303    users users_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (uuid);
 6   ALTER TABLE ONLY hr.users DROP CONSTRAINT users_pkey;
       hr            postgres    false    231                       2606    35305    info info_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_pkey PRIMARY KEY (uuid);
 9   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_pkey;
       lab_dip            postgres    false    252            #           2606    35307    recipe_entry recipe_entry_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY lab_dip.recipe_entry
    ADD CONSTRAINT recipe_entry_pkey PRIMARY KEY (uuid);
 I   ALTER TABLE ONLY lab_dip.recipe_entry DROP CONSTRAINT recipe_entry_pkey;
       lab_dip            postgres    false    255            !           2606    35309    recipe recipe_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY lab_dip.recipe
    ADD CONSTRAINT recipe_pkey PRIMARY KEY (uuid);
 =   ALTER TABLE ONLY lab_dip.recipe DROP CONSTRAINT recipe_pkey;
       lab_dip            postgres    false    254            '           2606    35311 *   shade_recipe_entry shade_recipe_entry_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY lab_dip.shade_recipe_entry
    ADD CONSTRAINT shade_recipe_entry_pkey PRIMARY KEY (uuid);
 U   ALTER TABLE ONLY lab_dip.shade_recipe_entry DROP CONSTRAINT shade_recipe_entry_pkey;
       lab_dip            postgres    false    259            %           2606    35313    shade_recipe shade_recipe_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY lab_dip.shade_recipe
    ADD CONSTRAINT shade_recipe_pkey PRIMARY KEY (uuid);
 I   ALTER TABLE ONLY lab_dip.shade_recipe DROP CONSTRAINT shade_recipe_pkey;
       lab_dip            postgres    false    258            )           2606    35315    info info_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY material.info DROP CONSTRAINT info_pkey;
       material            postgres    false    260            +           2606    35317    section section_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY material.section
    ADD CONSTRAINT section_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY material.section DROP CONSTRAINT section_pkey;
       material            postgres    false    261            -           2606    35319    stock stock_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY material.stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (uuid);
 <   ALTER TABLE ONLY material.stock DROP CONSTRAINT stock_pkey;
       material            postgres    false    262            /           2606    35321    stock_to_sfg stock_to_sfg_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_pkey;
       material            postgres    false    263            1           2606    35323    trx trx_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY material.trx
    ADD CONSTRAINT trx_pkey PRIMARY KEY (uuid);
 8   ALTER TABLE ONLY material.trx DROP CONSTRAINT trx_pkey;
       material            postgres    false    264            3           2606    35325    type type_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY material.type
    ADD CONSTRAINT type_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY material.type DROP CONSTRAINT type_pkey;
       material            postgres    false    265            5           2606    35327    used used_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY material.used
    ADD CONSTRAINT used_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY material.used DROP CONSTRAINT used_pkey;
       material            postgres    false    266            �           2606    35329    buyer buyer_name_unique 
   CONSTRAINT     R   ALTER TABLE ONLY public.buyer
    ADD CONSTRAINT buyer_name_unique UNIQUE (name);
 A   ALTER TABLE ONLY public.buyer DROP CONSTRAINT buyer_name_unique;
       public            postgres    false    232            �           2606    35331    buyer buyer_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.buyer
    ADD CONSTRAINT buyer_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY public.buyer DROP CONSTRAINT buyer_pkey;
       public            postgres    false    232            �           2606    35333    factory factory_name_unique 
   CONSTRAINT     V   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_name_unique UNIQUE (name);
 E   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_name_unique;
       public            postgres    false    233            �           2606    35335    factory factory_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_pkey;
       public            postgres    false    233            7           2606    35337    machine machine_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.machine
    ADD CONSTRAINT machine_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY public.machine DROP CONSTRAINT machine_pkey;
       public            postgres    false    267            �           2606    35339    marketing marketing_name_unique 
   CONSTRAINT     Z   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_name_unique UNIQUE (name);
 I   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_name_unique;
       public            postgres    false    234            �           2606    35341    marketing marketing_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_pkey;
       public            postgres    false    234            �           2606    35343 %   merchandiser merchandiser_name_unique 
   CONSTRAINT     `   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_name_unique UNIQUE (name);
 O   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_name_unique;
       public            postgres    false    235            �           2606    35345    merchandiser merchandiser_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_pkey PRIMARY KEY (uuid);
 H   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_pkey;
       public            postgres    false    235                       2606    35347    party party_name_unique 
   CONSTRAINT     R   ALTER TABLE ONLY public.party
    ADD CONSTRAINT party_name_unique UNIQUE (name);
 A   ALTER TABLE ONLY public.party DROP CONSTRAINT party_name_unique;
       public            postgres    false    236                       2606    35349    party party_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.party
    ADD CONSTRAINT party_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY public.party DROP CONSTRAINT party_pkey;
       public            postgres    false    236                       2606    35351    properties properties_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY public.properties DROP CONSTRAINT properties_pkey;
       public            postgres    false    237            9           2606    35353    section section_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.section
    ADD CONSTRAINT section_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY public.section DROP CONSTRAINT section_pkey;
       public            postgres    false    268            ;           2606    35355    description description_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY purchase.description
    ADD CONSTRAINT description_pkey PRIMARY KEY (uuid);
 H   ALTER TABLE ONLY purchase.description DROP CONSTRAINT description_pkey;
       purchase            postgres    false    270            =           2606    35357    entry entry_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY purchase.entry
    ADD CONSTRAINT entry_pkey PRIMARY KEY (uuid);
 <   ALTER TABLE ONLY purchase.entry DROP CONSTRAINT entry_pkey;
       purchase            postgres    false    271            ?           2606    35359    vendor vendor_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY purchase.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY purchase.vendor DROP CONSTRAINT vendor_pkey;
       purchase            postgres    false    272            A           2606    35361 "   assembly_stock assembly_stock_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY slider.assembly_stock
    ADD CONSTRAINT assembly_stock_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY slider.assembly_stock DROP CONSTRAINT assembly_stock_pkey;
       slider            postgres    false    273            C           2606    35363 .   coloring_transaction coloring_transaction_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_pkey PRIMARY KEY (uuid);
 X   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_pkey;
       slider            postgres    false    274            E           2606    35365    die_casting die_casting_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_pkey;
       slider            postgres    false    275            G           2606    35367 2   die_casting_production die_casting_production_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_pkey PRIMARY KEY (uuid);
 \   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_pkey;
       slider            postgres    false    276            I           2606    35369 @   die_casting_to_assembly_stock die_casting_to_assembly_stock_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock
    ADD CONSTRAINT die_casting_to_assembly_stock_pkey PRIMARY KEY (uuid);
 j   ALTER TABLE ONLY slider.die_casting_to_assembly_stock DROP CONSTRAINT die_casting_to_assembly_stock_pkey;
       slider            postgres    false    277            K           2606    35371 4   die_casting_transaction die_casting_transaction_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_pkey PRIMARY KEY (uuid);
 ^   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_pkey;
       slider            postgres    false    278            M           2606    35373    production production_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY slider.production
    ADD CONSTRAINT production_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY slider.production DROP CONSTRAINT production_pkey;
       slider            postgres    false    279                       2606    35375    stock stock_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY slider.stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY slider.stock DROP CONSTRAINT stock_pkey;
       slider            postgres    false    238            O           2606    35377    transaction transaction_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_pkey;
       slider            postgres    false    280            Q           2606    35379 (   trx_against_stock trx_against_stock_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY slider.trx_against_stock
    ADD CONSTRAINT trx_against_stock_pkey PRIMARY KEY (uuid);
 R   ALTER TABLE ONLY slider.trx_against_stock DROP CONSTRAINT trx_against_stock_pkey;
       slider            postgres    false    281            U           2606    35381    batch_entry batch_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY thread.batch_entry
    ADD CONSTRAINT batch_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY thread.batch_entry DROP CONSTRAINT batch_entry_pkey;
       thread            postgres    false    284            W           2606    35383 2   batch_entry_production batch_entry_production_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY thread.batch_entry_production
    ADD CONSTRAINT batch_entry_production_pkey PRIMARY KEY (uuid);
 \   ALTER TABLE ONLY thread.batch_entry_production DROP CONSTRAINT batch_entry_production_pkey;
       thread            postgres    false    285            Y           2606    35385 $   batch_entry_trx batch_entry_trx_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY thread.batch_entry_trx
    ADD CONSTRAINT batch_entry_trx_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY thread.batch_entry_trx DROP CONSTRAINT batch_entry_trx_pkey;
       thread            postgres    false    286            S           2606    35387    batch batch_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_pkey;
       thread            postgres    false    283            ]           2606    35389     challan_entry challan_entry_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_pkey;
       thread            postgres    false    288            [           2606    35391    challan challan_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_pkey;
       thread            postgres    false    287            _           2606    35393 !   count_length count_length_uuid_pk 
   CONSTRAINT     a   ALTER TABLE ONLY thread.count_length
    ADD CONSTRAINT count_length_uuid_pk PRIMARY KEY (uuid);
 K   ALTER TABLE ONLY thread.count_length DROP CONSTRAINT count_length_uuid_pk;
       thread            postgres    false    289            a           2606    35395     dyes_category dyes_category_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY thread.dyes_category
    ADD CONSTRAINT dyes_category_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY thread.dyes_category DROP CONSTRAINT dyes_category_pkey;
       thread            postgres    false    290            c           2606    35397    order_entry order_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_pkey;
       thread            postgres    false    291            e           2606    35399    order_info order_info_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_pkey;
       thread            postgres    false    293            g           2606    35401    programs programs_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_pkey;
       thread            postgres    false    294            k           2606    35403    batch_entry batch_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY zipper.batch_entry
    ADD CONSTRAINT batch_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY zipper.batch_entry DROP CONSTRAINT batch_entry_pkey;
       zipper            postgres    false    296            i           2606    35405    batch batch_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY zipper.batch
    ADD CONSTRAINT batch_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY zipper.batch DROP CONSTRAINT batch_pkey;
       zipper            postgres    false    295            m           2606    35407 &   batch_production batch_production_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY zipper.batch_production
    ADD CONSTRAINT batch_production_pkey PRIMARY KEY (uuid);
 P   ALTER TABLE ONLY zipper.batch_production DROP CONSTRAINT batch_production_pkey;
       zipper            postgres    false    298            q           2606    35409 F   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_pkey PRIMARY KEY (uuid);
 p   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_pkey;
       zipper            postgres    false    300            o           2606    35411 0   dyed_tape_transaction dyed_tape_transaction_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY zipper.dyed_tape_transaction
    ADD CONSTRAINT dyed_tape_transaction_pkey PRIMARY KEY (uuid);
 Z   ALTER TABLE ONLY zipper.dyed_tape_transaction DROP CONSTRAINT dyed_tape_transaction_pkey;
       zipper            postgres    false    299            u           2606    35413 (   dying_batch_entry dying_batch_entry_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY zipper.dying_batch_entry
    ADD CONSTRAINT dying_batch_entry_pkey PRIMARY KEY (uuid);
 R   ALTER TABLE ONLY zipper.dying_batch_entry DROP CONSTRAINT dying_batch_entry_pkey;
       zipper            postgres    false    302            s           2606    35415    dying_batch dying_batch_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY zipper.dying_batch
    ADD CONSTRAINT dying_batch_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY zipper.dying_batch DROP CONSTRAINT dying_batch_pkey;
       zipper            postgres    false    301            w           2606    35417 R   material_trx_against_order_description material_trx_against_order_description_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_pkey PRIMARY KEY (uuid);
 |   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_pkey;
       zipper            postgres    false    304            	           2606    35419 (   order_description order_description_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_pkey PRIMARY KEY (uuid);
 R   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_pkey;
       zipper            postgres    false    239                       2606    35421    order_entry order_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY zipper.order_entry
    ADD CONSTRAINT order_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY zipper.order_entry DROP CONSTRAINT order_entry_pkey;
       zipper            postgres    false    240                       2606    35423    order_info order_info_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_pkey;
       zipper            postgres    false    242            {           2606    35425 "   planning_entry planning_entry_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY zipper.planning_entry
    ADD CONSTRAINT planning_entry_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY zipper.planning_entry DROP CONSTRAINT planning_entry_pkey;
       zipper            postgres    false    306            y           2606    35427    planning planning_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY zipper.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (week);
 @   ALTER TABLE ONLY zipper.planning DROP CONSTRAINT planning_pkey;
       zipper            postgres    false    305                       2606    35429    sfg sfg_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY zipper.sfg
    ADD CONSTRAINT sfg_pkey PRIMARY KEY (uuid);
 6   ALTER TABLE ONLY zipper.sfg DROP CONSTRAINT sfg_pkey;
       zipper            postgres    false    243            }           2606    35431 "   sfg_production sfg_production_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY zipper.sfg_production
    ADD CONSTRAINT sfg_production_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY zipper.sfg_production DROP CONSTRAINT sfg_production_pkey;
       zipper            postgres    false    307                       2606    35433 $   sfg_transaction sfg_transaction_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_pkey;
       zipper            postgres    false    308                       2606    35435    tape_coil tape_coil_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_pkey;
       zipper            postgres    false    244            �           2606    35437 .   tape_coil_production tape_coil_production_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY zipper.tape_coil_production
    ADD CONSTRAINT tape_coil_production_pkey PRIMARY KEY (uuid);
 X   ALTER TABLE ONLY zipper.tape_coil_production DROP CONSTRAINT tape_coil_production_pkey;
       zipper            postgres    false    309            �           2606    35439 *   tape_coil_required tape_coil_required_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_pkey PRIMARY KEY (uuid);
 T   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_pkey;
       zipper            postgres    false    310            �           2606    35441 ,   tape_coil_to_dyeing tape_coil_to_dyeing_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_pkey PRIMARY KEY (uuid);
 V   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_pkey;
       zipper            postgres    false    311            �           2606    35443    tape_trx tape_to_coil_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_to_coil_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_to_coil_pkey;
       zipper            postgres    false    312            M           2620    35444 :   pi_cash_entry sfg_after_commercial_pi_entry_delete_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_commercial_pi_entry_delete_trigger AFTER DELETE ON commercial.pi_cash_entry FOR EACH ROW EXECUTE FUNCTION commercial.sfg_after_commercial_pi_entry_delete_function();
 W   DROP TRIGGER sfg_after_commercial_pi_entry_delete_trigger ON commercial.pi_cash_entry;
    
   commercial          postgres    false    224    325            N           2620    35445 :   pi_cash_entry sfg_after_commercial_pi_entry_insert_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_commercial_pi_entry_insert_trigger AFTER INSERT ON commercial.pi_cash_entry FOR EACH ROW EXECUTE FUNCTION commercial.sfg_after_commercial_pi_entry_insert_function();
 W   DROP TRIGGER sfg_after_commercial_pi_entry_insert_trigger ON commercial.pi_cash_entry;
    
   commercial          postgres    false    224    326            O           2620    35446 :   pi_cash_entry sfg_after_commercial_pi_entry_update_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_commercial_pi_entry_update_trigger AFTER UPDATE ON commercial.pi_cash_entry FOR EACH ROW EXECUTE FUNCTION commercial.sfg_after_commercial_pi_entry_update_function();
 W   DROP TRIGGER sfg_after_commercial_pi_entry_update_trigger ON commercial.pi_cash_entry;
    
   commercial          postgres    false    224    333            P           2620    35447 5   challan_entry packing_list_after_challan_entry_delete    TRIGGER     �   CREATE TRIGGER packing_list_after_challan_entry_delete AFTER DELETE ON delivery.challan_entry FOR EACH ROW EXECUTE FUNCTION delivery.packing_list_after_challan_entry_delete_function();
 P   DROP TRIGGER packing_list_after_challan_entry_delete ON delivery.challan_entry;
       delivery          postgres    false    336    227            Q           2620    35448 5   challan_entry packing_list_after_challan_entry_insert    TRIGGER     �   CREATE TRIGGER packing_list_after_challan_entry_insert AFTER INSERT ON delivery.challan_entry FOR EACH ROW EXECUTE FUNCTION delivery.packing_list_after_challan_entry_insert_function();
 P   DROP TRIGGER packing_list_after_challan_entry_insert ON delivery.challan_entry;
       delivery          postgres    false    227    337            R           2620    35449 5   challan_entry packing_list_after_challan_entry_update    TRIGGER     �   CREATE TRIGGER packing_list_after_challan_entry_update AFTER UPDATE ON delivery.challan_entry FOR EACH ROW EXECUTE FUNCTION delivery.packing_list_after_challan_entry_update_function();
 P   DROP TRIGGER packing_list_after_challan_entry_update ON delivery.challan_entry;
       delivery          postgres    false    338    227            S           2620    35450 :   packing_list_entry sfg_after_challan_receive_status_delete    TRIGGER     �   CREATE TRIGGER sfg_after_challan_receive_status_delete AFTER DELETE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_challan_receive_status_delete_function();
 U   DROP TRIGGER sfg_after_challan_receive_status_delete ON delivery.packing_list_entry;
       delivery          postgres    false    230    339            T           2620    35451 :   packing_list_entry sfg_after_challan_receive_status_insert    TRIGGER     �   CREATE TRIGGER sfg_after_challan_receive_status_insert AFTER INSERT ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_challan_receive_status_insert_function();
 U   DROP TRIGGER sfg_after_challan_receive_status_insert ON delivery.packing_list_entry;
       delivery          postgres    false    340    230            U           2620    35452 :   packing_list_entry sfg_after_challan_receive_status_update    TRIGGER     �   CREATE TRIGGER sfg_after_challan_receive_status_update AFTER UPDATE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_challan_receive_status_update_function();
 U   DROP TRIGGER sfg_after_challan_receive_status_update ON delivery.packing_list_entry;
       delivery          postgres    false    230    341            V           2620    35453 6   packing_list_entry sfg_after_packing_list_entry_delete    TRIGGER     �   CREATE TRIGGER sfg_after_packing_list_entry_delete AFTER DELETE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_packing_list_entry_delete_function();
 Q   DROP TRIGGER sfg_after_packing_list_entry_delete ON delivery.packing_list_entry;
       delivery          postgres    false    230    342            W           2620    35454 6   packing_list_entry sfg_after_packing_list_entry_insert    TRIGGER     �   CREATE TRIGGER sfg_after_packing_list_entry_insert AFTER INSERT ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_packing_list_entry_insert_function();
 Q   DROP TRIGGER sfg_after_packing_list_entry_insert ON delivery.packing_list_entry;
       delivery          postgres    false    230    343            X           2620    35455 6   packing_list_entry sfg_after_packing_list_entry_update    TRIGGER     �   CREATE TRIGGER sfg_after_packing_list_entry_update AFTER UPDATE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_packing_list_entry_update_function();
 Q   DROP TRIGGER sfg_after_packing_list_entry_update ON delivery.packing_list_entry;
       delivery          postgres    false    230    344            [           2620    35456 .   info material_stock_after_material_info_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_material_info_delete AFTER DELETE ON material.info FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_info_delete();
 I   DROP TRIGGER material_stock_after_material_info_delete ON material.info;
       material          postgres    false    260    345            \           2620    35457 .   info material_stock_after_material_info_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_material_info_insert AFTER INSERT ON material.info FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_info_insert();
 I   DROP TRIGGER material_stock_after_material_info_insert ON material.info;
       material          postgres    false    260    346            `           2620    35458 ,   trx material_stock_after_material_trx_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_material_trx_delete AFTER DELETE ON material.trx FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_trx_delete();
 G   DROP TRIGGER material_stock_after_material_trx_delete ON material.trx;
       material          postgres    false    264    314            a           2620    35459 ,   trx material_stock_after_material_trx_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_material_trx_insert AFTER INSERT ON material.trx FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_trx_insert();
 G   DROP TRIGGER material_stock_after_material_trx_insert ON material.trx;
       material          postgres    false    319    264            b           2620    35460 ,   trx material_stock_after_material_trx_update    TRIGGER     �   CREATE TRIGGER material_stock_after_material_trx_update AFTER UPDATE ON material.trx FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_trx_update();
 G   DROP TRIGGER material_stock_after_material_trx_update ON material.trx;
       material          postgres    false    264    347            c           2620    35461 .   used material_stock_after_material_used_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_material_used_delete AFTER DELETE ON material.used FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_used_delete();
 I   DROP TRIGGER material_stock_after_material_used_delete ON material.used;
       material          postgres    false    348    266            d           2620    35462 .   used material_stock_after_material_used_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_material_used_insert AFTER INSERT ON material.used FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_used_insert();
 I   DROP TRIGGER material_stock_after_material_used_insert ON material.used;
       material          postgres    false    349    266            e           2620    35463 .   used material_stock_after_material_used_update    TRIGGER     �   CREATE TRIGGER material_stock_after_material_used_update AFTER UPDATE ON material.used FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_used_update();
 I   DROP TRIGGER material_stock_after_material_used_update ON material.used;
       material          postgres    false    266    350            ]           2620    35464 9   stock_to_sfg material_stock_sfg_after_stock_to_sfg_delete    TRIGGER     �   CREATE TRIGGER material_stock_sfg_after_stock_to_sfg_delete AFTER DELETE ON material.stock_to_sfg FOR EACH ROW EXECUTE FUNCTION material.material_stock_sfg_after_stock_to_sfg_delete();
 T   DROP TRIGGER material_stock_sfg_after_stock_to_sfg_delete ON material.stock_to_sfg;
       material          postgres    false    354    263            ^           2620    35465 9   stock_to_sfg material_stock_sfg_after_stock_to_sfg_insert    TRIGGER     �   CREATE TRIGGER material_stock_sfg_after_stock_to_sfg_insert AFTER INSERT ON material.stock_to_sfg FOR EACH ROW EXECUTE FUNCTION material.material_stock_sfg_after_stock_to_sfg_insert();
 T   DROP TRIGGER material_stock_sfg_after_stock_to_sfg_insert ON material.stock_to_sfg;
       material          postgres    false    356    263            _           2620    35466 9   stock_to_sfg material_stock_sfg_after_stock_to_sfg_update    TRIGGER     �   CREATE TRIGGER material_stock_sfg_after_stock_to_sfg_update AFTER UPDATE ON material.stock_to_sfg FOR EACH ROW EXECUTE FUNCTION material.material_stock_sfg_after_stock_to_sfg_update();
 T   DROP TRIGGER material_stock_sfg_after_stock_to_sfg_update ON material.stock_to_sfg;
       material          postgres    false    263    357            f           2620    35467 0   entry material_stock_after_purchase_entry_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_purchase_entry_delete AFTER DELETE ON purchase.entry FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_purchase_entry_delete();
 K   DROP TRIGGER material_stock_after_purchase_entry_delete ON purchase.entry;
       purchase          postgres    false    271    351            g           2620    35468 0   entry material_stock_after_purchase_entry_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_purchase_entry_insert AFTER INSERT ON purchase.entry FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_purchase_entry_insert();
 K   DROP TRIGGER material_stock_after_purchase_entry_insert ON purchase.entry;
       purchase          postgres    false    271    352            h           2620    35469 0   entry material_stock_after_purchase_entry_update    TRIGGER     �   CREATE TRIGGER material_stock_after_purchase_entry_update AFTER UPDATE ON purchase.entry FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_purchase_entry_update();
 K   DROP TRIGGER material_stock_after_purchase_entry_update ON purchase.entry;
       purchase          postgres    false    353    271            o           2620    35470 W   die_casting_to_assembly_stock assembly_stock_after_die_casting_to_assembly_stock_delete    TRIGGER     �   CREATE TRIGGER assembly_stock_after_die_casting_to_assembly_stock_delete AFTER DELETE ON slider.die_casting_to_assembly_stock FOR EACH ROW EXECUTE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_delete_funct();
 p   DROP TRIGGER assembly_stock_after_die_casting_to_assembly_stock_delete ON slider.die_casting_to_assembly_stock;
       slider          postgres    false    365    277            p           2620    35471 W   die_casting_to_assembly_stock assembly_stock_after_die_casting_to_assembly_stock_insert    TRIGGER     �   CREATE TRIGGER assembly_stock_after_die_casting_to_assembly_stock_insert AFTER INSERT ON slider.die_casting_to_assembly_stock FOR EACH ROW EXECUTE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_insert_funct();
 p   DROP TRIGGER assembly_stock_after_die_casting_to_assembly_stock_insert ON slider.die_casting_to_assembly_stock;
       slider          postgres    false    366    277            q           2620    35472 W   die_casting_to_assembly_stock assembly_stock_after_die_casting_to_assembly_stock_update    TRIGGER     �   CREATE TRIGGER assembly_stock_after_die_casting_to_assembly_stock_update AFTER UPDATE ON slider.die_casting_to_assembly_stock FOR EACH ROW EXECUTE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_update_funct();
 p   DROP TRIGGER assembly_stock_after_die_casting_to_assembly_stock_update ON slider.die_casting_to_assembly_stock;
       slider          postgres    false    277    367            l           2620    35473 M   die_casting_production slider_die_casting_after_die_casting_production_delete    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_die_casting_production_delete AFTER DELETE ON slider.die_casting_production FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_die_casting_production_delete();
 f   DROP TRIGGER slider_die_casting_after_die_casting_production_delete ON slider.die_casting_production;
       slider          postgres    false    368    276            m           2620    35474 M   die_casting_production slider_die_casting_after_die_casting_production_insert    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_die_casting_production_insert AFTER INSERT ON slider.die_casting_production FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_die_casting_production_insert();
 f   DROP TRIGGER slider_die_casting_after_die_casting_production_insert ON slider.die_casting_production;
       slider          postgres    false    276    369            n           2620    35475 M   die_casting_production slider_die_casting_after_die_casting_production_update    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_die_casting_production_update AFTER UPDATE ON slider.die_casting_production FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_die_casting_production_update();
 f   DROP TRIGGER slider_die_casting_after_die_casting_production_update ON slider.die_casting_production;
       slider          postgres    false    276    370            {           2620    35476 C   trx_against_stock slider_die_casting_after_trx_against_stock_delete    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_trx_against_stock_delete AFTER DELETE ON slider.trx_against_stock FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_trx_against_stock_delete();
 \   DROP TRIGGER slider_die_casting_after_trx_against_stock_delete ON slider.trx_against_stock;
       slider          postgres    false    281    371            |           2620    35477 C   trx_against_stock slider_die_casting_after_trx_against_stock_insert    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_trx_against_stock_insert AFTER INSERT ON slider.trx_against_stock FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_trx_against_stock_insert();
 \   DROP TRIGGER slider_die_casting_after_trx_against_stock_insert ON slider.trx_against_stock;
       slider          postgres    false    281    372            }           2620    35478 C   trx_against_stock slider_die_casting_after_trx_against_stock_update    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_trx_against_stock_update AFTER UPDATE ON slider.trx_against_stock FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_trx_against_stock_update();
 \   DROP TRIGGER slider_die_casting_after_trx_against_stock_update ON slider.trx_against_stock;
       slider          postgres    false    281    373            i           2620    35479 C   coloring_transaction slider_stock_after_coloring_transaction_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_coloring_transaction_delete AFTER DELETE ON slider.coloring_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_coloring_transaction_delete();
 \   DROP TRIGGER slider_stock_after_coloring_transaction_delete ON slider.coloring_transaction;
       slider          postgres    false    317    274            j           2620    35480 C   coloring_transaction slider_stock_after_coloring_transaction_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_coloring_transaction_insert AFTER INSERT ON slider.coloring_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_coloring_transaction_insert();
 \   DROP TRIGGER slider_stock_after_coloring_transaction_insert ON slider.coloring_transaction;
       slider          postgres    false    318    274            k           2620    35481 C   coloring_transaction slider_stock_after_coloring_transaction_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_coloring_transaction_update AFTER UPDATE ON slider.coloring_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_coloring_transaction_update();
 \   DROP TRIGGER slider_stock_after_coloring_transaction_update ON slider.coloring_transaction;
       slider          postgres    false    274    374            r           2620    35482 I   die_casting_transaction slider_stock_after_die_casting_transaction_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_die_casting_transaction_delete AFTER DELETE ON slider.die_casting_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_die_casting_transaction_delete();
 b   DROP TRIGGER slider_stock_after_die_casting_transaction_delete ON slider.die_casting_transaction;
       slider          postgres    false    375    278            s           2620    35483 I   die_casting_transaction slider_stock_after_die_casting_transaction_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_die_casting_transaction_insert AFTER INSERT ON slider.die_casting_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_die_casting_transaction_insert();
 b   DROP TRIGGER slider_stock_after_die_casting_transaction_insert ON slider.die_casting_transaction;
       slider          postgres    false    376    278            t           2620    35484 I   die_casting_transaction slider_stock_after_die_casting_transaction_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_die_casting_transaction_update AFTER UPDATE ON slider.die_casting_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_die_casting_transaction_update();
 b   DROP TRIGGER slider_stock_after_die_casting_transaction_update ON slider.die_casting_transaction;
       slider          postgres    false    278    377            u           2620    35485 6   production slider_stock_after_slider_production_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_slider_production_delete AFTER DELETE ON slider.production FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_slider_production_delete();
 O   DROP TRIGGER slider_stock_after_slider_production_delete ON slider.production;
       slider          postgres    false    378    279            v           2620    35486 6   production slider_stock_after_slider_production_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_slider_production_insert AFTER INSERT ON slider.production FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_slider_production_insert();
 O   DROP TRIGGER slider_stock_after_slider_production_insert ON slider.production;
       slider          postgres    false    379    279            w           2620    35487 6   production slider_stock_after_slider_production_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_slider_production_update AFTER UPDATE ON slider.production FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_slider_production_update();
 O   DROP TRIGGER slider_stock_after_slider_production_update ON slider.production;
       slider          postgres    false    380    279            x           2620    35488 1   transaction slider_stock_after_transaction_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_transaction_delete AFTER DELETE ON slider.transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_transaction_delete();
 J   DROP TRIGGER slider_stock_after_transaction_delete ON slider.transaction;
       slider          postgres    false    381    280            y           2620    35489 1   transaction slider_stock_after_transaction_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_transaction_insert AFTER INSERT ON slider.transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_transaction_insert();
 J   DROP TRIGGER slider_stock_after_transaction_insert ON slider.transaction;
       slider          postgres    false    280    382            z           2620    35490 1   transaction slider_stock_after_transaction_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_transaction_update AFTER UPDATE ON slider.transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_transaction_update();
 J   DROP TRIGGER slider_stock_after_transaction_update ON slider.transaction;
       slider          postgres    false    280    383            ~           2620    35491 7   batch order_entry_after_batch_is_drying_update_function    TRIGGER     �   CREATE TRIGGER order_entry_after_batch_is_drying_update_function AFTER UPDATE ON thread.batch FOR EACH ROW EXECUTE FUNCTION thread.order_entry_after_batch_is_drying_update();
 P   DROP TRIGGER order_entry_after_batch_is_drying_update_function ON thread.batch;
       thread          postgres    false    384    283                       2620    35492 7   batch order_entry_after_batch_is_dyeing_update_function    TRIGGER     �   CREATE TRIGGER order_entry_after_batch_is_dyeing_update_function AFTER UPDATE OF is_drying_complete ON thread.batch FOR EACH ROW EXECUTE FUNCTION thread.order_entry_after_batch_is_dyeing_update();
 P   DROP TRIGGER order_entry_after_batch_is_dyeing_update_function ON thread.batch;
       thread          postgres    false    283    385    283            �           2620    35493 M   batch_entry_production thread_batch_entry_after_batch_entry_production_delete    TRIGGER     �   CREATE TRIGGER thread_batch_entry_after_batch_entry_production_delete AFTER DELETE ON thread.batch_entry_production FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_after_batch_entry_production_delete_funct();
 f   DROP TRIGGER thread_batch_entry_after_batch_entry_production_delete ON thread.batch_entry_production;
       thread          postgres    false    358    285            �           2620    35494 M   batch_entry_production thread_batch_entry_after_batch_entry_production_insert    TRIGGER     �   CREATE TRIGGER thread_batch_entry_after_batch_entry_production_insert AFTER INSERT ON thread.batch_entry_production FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_after_batch_entry_production_insert_funct();
 f   DROP TRIGGER thread_batch_entry_after_batch_entry_production_insert ON thread.batch_entry_production;
       thread          postgres    false    285    359            �           2620    35495 M   batch_entry_production thread_batch_entry_after_batch_entry_production_update    TRIGGER     �   CREATE TRIGGER thread_batch_entry_after_batch_entry_production_update AFTER UPDATE ON thread.batch_entry_production FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_after_batch_entry_production_update_funct();
 f   DROP TRIGGER thread_batch_entry_after_batch_entry_production_update ON thread.batch_entry_production;
       thread          postgres    false    285    360            �           2620    35496 H   batch_entry_trx thread_batch_entry_and_order_entry_after_batch_entry_trx    TRIGGER     �   CREATE TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx AFTER INSERT ON thread.batch_entry_trx FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_funct();
 a   DROP TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx ON thread.batch_entry_trx;
       thread          postgres    false    286    362            �           2620    35497 O   batch_entry_trx thread_batch_entry_and_order_entry_after_batch_entry_trx_delete    TRIGGER     �   CREATE TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_delete AFTER DELETE ON thread.batch_entry_trx FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_delete();
 h   DROP TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_delete ON thread.batch_entry_trx;
       thread          postgres    false    286    361            �           2620    35498 O   batch_entry_trx thread_batch_entry_and_order_entry_after_batch_entry_trx_update    TRIGGER     �   CREATE TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_update AFTER UPDATE ON thread.batch_entry_trx FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_update();
 h   DROP TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_update ON thread.batch_entry_trx;
       thread          postgres    false    286    363            �           2620    35499 R   dyed_tape_transaction order_description_after_dyed_tape_transaction_delete_trigger    TRIGGER     �   CREATE TRIGGER order_description_after_dyed_tape_transaction_delete_trigger AFTER DELETE ON zipper.dyed_tape_transaction FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_dyed_tape_transaction_delete();
 k   DROP TRIGGER order_description_after_dyed_tape_transaction_delete_trigger ON zipper.dyed_tape_transaction;
       zipper          postgres    false    299    386            �           2620    35500 R   dyed_tape_transaction order_description_after_dyed_tape_transaction_insert_trigger    TRIGGER     �   CREATE TRIGGER order_description_after_dyed_tape_transaction_insert_trigger AFTER INSERT ON zipper.dyed_tape_transaction FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_dyed_tape_transaction_insert();
 k   DROP TRIGGER order_description_after_dyed_tape_transaction_insert_trigger ON zipper.dyed_tape_transaction;
       zipper          postgres    false    299    387            �           2620    35501 R   dyed_tape_transaction order_description_after_dyed_tape_transaction_update_trigger    TRIGGER     �   CREATE TRIGGER order_description_after_dyed_tape_transaction_update_trigger AFTER UPDATE ON zipper.dyed_tape_transaction FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_dyed_tape_transaction_update();
 k   DROP TRIGGER order_description_after_dyed_tape_transaction_update_trigger ON zipper.dyed_tape_transaction;
       zipper          postgres    false    299    388            Y           2620    35502 (   order_entry sfg_after_order_entry_delete    TRIGGER     �   CREATE TRIGGER sfg_after_order_entry_delete AFTER DELETE ON zipper.order_entry FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_order_entry_delete();
 A   DROP TRIGGER sfg_after_order_entry_delete ON zipper.order_entry;
       zipper          postgres    false    392    240            Z           2620    35503 (   order_entry sfg_after_order_entry_insert    TRIGGER     �   CREATE TRIGGER sfg_after_order_entry_insert AFTER INSERT ON zipper.order_entry FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_order_entry_insert();
 A   DROP TRIGGER sfg_after_order_entry_insert ON zipper.order_entry;
       zipper          postgres    false    240    393            �           2620    35504 6   sfg_production sfg_after_sfg_production_delete_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_production_delete_trigger AFTER DELETE ON zipper.sfg_production FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_production_delete_function();
 O   DROP TRIGGER sfg_after_sfg_production_delete_trigger ON zipper.sfg_production;
       zipper          postgres    false    307    394            �           2620    35505 6   sfg_production sfg_after_sfg_production_insert_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_production_insert_trigger AFTER INSERT ON zipper.sfg_production FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_production_insert_function();
 O   DROP TRIGGER sfg_after_sfg_production_insert_trigger ON zipper.sfg_production;
       zipper          postgres    false    307    395            �           2620    35506 6   sfg_production sfg_after_sfg_production_update_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_production_update_trigger AFTER UPDATE ON zipper.sfg_production FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_production_update_function();
 O   DROP TRIGGER sfg_after_sfg_production_update_trigger ON zipper.sfg_production;
       zipper          postgres    false    307    396            �           2620    35507 8   sfg_transaction sfg_after_sfg_transaction_delete_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_transaction_delete_trigger AFTER DELETE ON zipper.sfg_transaction FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_transaction_delete_function();
 Q   DROP TRIGGER sfg_after_sfg_transaction_delete_trigger ON zipper.sfg_transaction;
       zipper          postgres    false    308    397            �           2620    35508 8   sfg_transaction sfg_after_sfg_transaction_insert_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_transaction_insert_trigger AFTER INSERT ON zipper.sfg_transaction FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_transaction_insert_function();
 Q   DROP TRIGGER sfg_after_sfg_transaction_insert_trigger ON zipper.sfg_transaction;
       zipper          postgres    false    398    308            �           2620    35509 8   sfg_transaction sfg_after_sfg_transaction_update_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_transaction_update_trigger AFTER UPDATE ON zipper.sfg_transaction FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_transaction_update_function();
 Q   DROP TRIGGER sfg_after_sfg_transaction_update_trigger ON zipper.sfg_transaction;
       zipper          postgres    false    308    399            �           2620    35510 `   material_trx_against_order_description stock_after_material_trx_against_order_description_delete    TRIGGER     �   CREATE TRIGGER stock_after_material_trx_against_order_description_delete AFTER DELETE ON zipper.material_trx_against_order_description FOR EACH ROW EXECUTE FUNCTION zipper.stock_after_material_trx_against_order_description_delete_funct();
 y   DROP TRIGGER stock_after_material_trx_against_order_description_delete ON zipper.material_trx_against_order_description;
       zipper          postgres    false    304    400            �           2620    35511 `   material_trx_against_order_description stock_after_material_trx_against_order_description_insert    TRIGGER     �   CREATE TRIGGER stock_after_material_trx_against_order_description_insert AFTER INSERT ON zipper.material_trx_against_order_description FOR EACH ROW EXECUTE FUNCTION zipper.stock_after_material_trx_against_order_description_insert_funct();
 y   DROP TRIGGER stock_after_material_trx_against_order_description_insert ON zipper.material_trx_against_order_description;
       zipper          postgres    false    304    401            �           2620    35512 `   material_trx_against_order_description stock_after_material_trx_against_order_description_update    TRIGGER     �   CREATE TRIGGER stock_after_material_trx_against_order_description_update AFTER UPDATE ON zipper.material_trx_against_order_description FOR EACH ROW EXECUTE FUNCTION zipper.stock_after_material_trx_against_order_description_update_funct();
 y   DROP TRIGGER stock_after_material_trx_against_order_description_update ON zipper.material_trx_against_order_description;
       zipper          postgres    false    304    402            �           2620    35513 9   tape_coil_production tape_coil_after_tape_coil_production    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_coil_production AFTER INSERT ON zipper.tape_coil_production FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_coil_production();
 R   DROP TRIGGER tape_coil_after_tape_coil_production ON zipper.tape_coil_production;
       zipper          postgres    false    403    309            �           2620    35514 @   tape_coil_production tape_coil_after_tape_coil_production_delete    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_coil_production_delete AFTER DELETE ON zipper.tape_coil_production FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_coil_production_delete();
 Y   DROP TRIGGER tape_coil_after_tape_coil_production_delete ON zipper.tape_coil_production;
       zipper          postgres    false    404    309            �           2620    35515 @   tape_coil_production tape_coil_after_tape_coil_production_update    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_coil_production_update AFTER UPDATE ON zipper.tape_coil_production FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_coil_production_update();
 Y   DROP TRIGGER tape_coil_after_tape_coil_production_update ON zipper.tape_coil_production;
       zipper          postgres    false    309    405            �           2620    35516 .   tape_trx tape_coil_after_tape_trx_after_delete    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_trx_after_delete AFTER DELETE ON zipper.tape_trx FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_trx_delete();
 G   DROP TRIGGER tape_coil_after_tape_trx_after_delete ON zipper.tape_trx;
       zipper          postgres    false    406    312            �           2620    35517 .   tape_trx tape_coil_after_tape_trx_after_insert    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_trx_after_insert AFTER INSERT ON zipper.tape_trx FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_trx_insert();
 G   DROP TRIGGER tape_coil_after_tape_trx_after_insert ON zipper.tape_trx;
       zipper          postgres    false    312    407            �           2620    35518 .   tape_trx tape_coil_after_tape_trx_after_update    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_trx_after_update AFTER UPDATE ON zipper.tape_trx FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_trx_update();
 G   DROP TRIGGER tape_coil_after_tape_trx_after_update ON zipper.tape_trx;
       zipper          postgres    false    312    408            �           2620    35519 `   dyed_tape_transaction_from_stock tape_coil_and_order_description_after_dyed_tape_transaction_del    TRIGGER     �   CREATE TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_del AFTER DELETE ON zipper.dyed_tape_transaction_from_stock FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_del();
 y   DROP TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_del ON zipper.dyed_tape_transaction_from_stock;
       zipper          postgres    false    409    300            �           2620    35520 `   dyed_tape_transaction_from_stock tape_coil_and_order_description_after_dyed_tape_transaction_ins    TRIGGER     �   CREATE TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_ins AFTER INSERT ON zipper.dyed_tape_transaction_from_stock FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_ins();
 y   DROP TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_ins ON zipper.dyed_tape_transaction_from_stock;
       zipper          postgres    false    300    410            �           2620    35521 `   dyed_tape_transaction_from_stock tape_coil_and_order_description_after_dyed_tape_transaction_upd    TRIGGER     �   CREATE TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_upd AFTER UPDATE ON zipper.dyed_tape_transaction_from_stock FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_upd();
 y   DROP TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_upd ON zipper.dyed_tape_transaction_from_stock;
       zipper          postgres    false    411    300            �           2620    35522 4   tape_coil_to_dyeing tape_coil_to_dyeing_after_delete    TRIGGER     �   CREATE TRIGGER tape_coil_to_dyeing_after_delete AFTER DELETE ON zipper.tape_coil_to_dyeing FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_delete();
 M   DROP TRIGGER tape_coil_to_dyeing_after_delete ON zipper.tape_coil_to_dyeing;
       zipper          postgres    false    389    311            �           2620    35523 4   tape_coil_to_dyeing tape_coil_to_dyeing_after_insert    TRIGGER     �   CREATE TRIGGER tape_coil_to_dyeing_after_insert AFTER INSERT ON zipper.tape_coil_to_dyeing FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_insert();
 M   DROP TRIGGER tape_coil_to_dyeing_after_insert ON zipper.tape_coil_to_dyeing;
       zipper          postgres    false    390    311            �           2620    35524 4   tape_coil_to_dyeing tape_coil_to_dyeing_after_update    TRIGGER     �   CREATE TRIGGER tape_coil_to_dyeing_after_update AFTER UPDATE ON zipper.tape_coil_to_dyeing FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_update();
 M   DROP TRIGGER tape_coil_to_dyeing_after_update ON zipper.tape_coil_to_dyeing;
       zipper          postgres    false    311    391            �           2620    35525 A   batch_production zipper_batch_entry_after_batch_production_delete    TRIGGER     �   CREATE TRIGGER zipper_batch_entry_after_batch_production_delete AFTER DELETE ON zipper.batch_production FOR EACH ROW EXECUTE FUNCTION public.zipper_batch_entry_after_batch_production_delete();
 Z   DROP TRIGGER zipper_batch_entry_after_batch_production_delete ON zipper.batch_production;
       zipper          postgres    false    298    320            �           2620    35526 A   batch_production zipper_batch_entry_after_batch_production_insert    TRIGGER     �   CREATE TRIGGER zipper_batch_entry_after_batch_production_insert AFTER INSERT ON zipper.batch_production FOR EACH ROW EXECUTE FUNCTION public.zipper_batch_entry_after_batch_production_insert();
 Z   DROP TRIGGER zipper_batch_entry_after_batch_production_insert ON zipper.batch_production;
       zipper          postgres    false    321    298            �           2620    35527 A   batch_production zipper_batch_entry_after_batch_production_update    TRIGGER     �   CREATE TRIGGER zipper_batch_entry_after_batch_production_update AFTER UPDATE ON zipper.batch_production FOR EACH ROW EXECUTE FUNCTION public.zipper_batch_entry_after_batch_production_update();
 Z   DROP TRIGGER zipper_batch_entry_after_batch_production_update ON zipper.batch_production;
       zipper          postgres    false    355    298            �           2606    35528 "   bank bank_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.bank
    ADD CONSTRAINT bank_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 P   ALTER TABLE ONLY commercial.bank DROP CONSTRAINT bank_created_by_users_uuid_fk;
    
   commercial          postgres    false    219    3823    231            �           2606    35533    lc lc_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.lc
    ADD CONSTRAINT lc_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 L   ALTER TABLE ONLY commercial.lc DROP CONSTRAINT lc_created_by_users_uuid_fk;
    
   commercial          postgres    false    3823    221    231            �           2606    35538    lc lc_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.lc
    ADD CONSTRAINT lc_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 L   ALTER TABLE ONLY commercial.lc DROP CONSTRAINT lc_party_uuid_party_uuid_fk;
    
   commercial          postgres    false    3843    221    236            �           2606    35543 &   pi_cash pi_cash_bank_uuid_bank_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_bank_uuid_bank_uuid_fk FOREIGN KEY (bank_uuid) REFERENCES commercial.bank(uuid);
 T   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_bank_uuid_bank_uuid_fk;
    
   commercial          postgres    false    3805    223    219            �           2606    35548 (   pi_cash pi_cash_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 V   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_created_by_users_uuid_fk;
    
   commercial          postgres    false    3823    223    231            �           2606    35553 8   pi_cash_entry pi_cash_entry_pi_cash_uuid_pi_cash_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_pi_cash_uuid_pi_cash_uuid_fk FOREIGN KEY (pi_cash_uuid) REFERENCES commercial.pi_cash(uuid);
 f   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_pi_cash_uuid_pi_cash_uuid_fk;
    
   commercial          postgres    false    3809    224    223            �           2606    35558 0   pi_cash_entry pi_cash_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 ^   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_sfg_uuid_sfg_uuid_fk;
    
   commercial          postgres    false    3855    224    243            �           2606    35563 G   pi_cash_entry pi_cash_entry_thread_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_thread_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (thread_order_entry_uuid) REFERENCES thread.order_entry(uuid);
 u   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_thread_order_entry_uuid_order_entry_uuid_fk;
    
   commercial          postgres    false    3939    224    291            �           2606    35568 ,   pi_cash pi_cash_factory_uuid_factory_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_factory_uuid_factory_uuid_fk FOREIGN KEY (factory_uuid) REFERENCES public.factory(uuid);
 Z   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_factory_uuid_factory_uuid_fk;
    
   commercial          postgres    false    3831    223    233            �           2606    35573 "   pi_cash pi_cash_lc_uuid_lc_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_lc_uuid_lc_uuid_fk FOREIGN KEY (lc_uuid) REFERENCES commercial.lc(uuid);
 P   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_lc_uuid_lc_uuid_fk;
    
   commercial          postgres    false    3807    223    221            �           2606    35578 0   pi_cash pi_cash_marketing_uuid_marketing_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_marketing_uuid_marketing_uuid_fk FOREIGN KEY (marketing_uuid) REFERENCES public.marketing(uuid);
 ^   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_marketing_uuid_marketing_uuid_fk;
    
   commercial          postgres    false    3835    234    223            �           2606    35583 6   pi_cash pi_cash_merchandiser_uuid_merchandiser_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_merchandiser_uuid_merchandiser_uuid_fk FOREIGN KEY (merchandiser_uuid) REFERENCES public.merchandiser(uuid);
 d   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_merchandiser_uuid_merchandiser_uuid_fk;
    
   commercial          postgres    false    223    3839    235            �           2606    35588 (   pi_cash pi_cash_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 V   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_party_uuid_party_uuid_fk;
    
   commercial          postgres    false    223    236    3843            �           2606    35593 '   challan challan_assign_to_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_assign_to_users_uuid_fk FOREIGN KEY (assign_to) REFERENCES hr.users(uuid);
 S   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_assign_to_users_uuid_fk;
       delivery          postgres    false    231    226    3823            �           2606    35598 (   challan challan_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_created_by_users_uuid_fk;
       delivery          postgres    false    226    3823    231            �           2606    35603 8   challan_entry challan_entry_challan_uuid_challan_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan_entry
    ADD CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk FOREIGN KEY (challan_uuid) REFERENCES delivery.challan(uuid);
 d   ALTER TABLE ONLY delivery.challan_entry DROP CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk;
       delivery          postgres    false    3813    227    226            �           2606    35608 B   challan_entry challan_entry_packing_list_uuid_packing_list_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan_entry
    ADD CONSTRAINT challan_entry_packing_list_uuid_packing_list_uuid_fk FOREIGN KEY (packing_list_uuid) REFERENCES delivery.packing_list(uuid);
 n   ALTER TABLE ONLY delivery.challan_entry DROP CONSTRAINT challan_entry_packing_list_uuid_packing_list_uuid_fk;
       delivery          postgres    false    229    3817    227            �           2606    35613 2   challan challan_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 ^   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_order_info_uuid_order_info_uuid_fk;
       delivery          postgres    false    242    3853    226            �           2606    35618 6   packing_list packing_list_challan_uuid_challan_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_challan_uuid_challan_uuid_fk FOREIGN KEY (challan_uuid) REFERENCES delivery.challan(uuid);
 b   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_challan_uuid_challan_uuid_fk;
       delivery          postgres    false    226    229    3813            �           2606    35623 2   packing_list packing_list_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_created_by_users_uuid_fk;
       delivery          postgres    false    231    229    3823            �           2606    35628 L   packing_list_entry packing_list_entry_packing_list_uuid_packing_list_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list_entry
    ADD CONSTRAINT packing_list_entry_packing_list_uuid_packing_list_uuid_fk FOREIGN KEY (packing_list_uuid) REFERENCES delivery.packing_list(uuid);
 x   ALTER TABLE ONLY delivery.packing_list_entry DROP CONSTRAINT packing_list_entry_packing_list_uuid_packing_list_uuid_fk;
       delivery          postgres    false    230    3817    229            �           2606    35633 :   packing_list_entry packing_list_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list_entry
    ADD CONSTRAINT packing_list_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 f   ALTER TABLE ONLY delivery.packing_list_entry DROP CONSTRAINT packing_list_entry_sfg_uuid_sfg_uuid_fk;
       delivery          postgres    false    3855    230    243            �           2606    35638 <   packing_list packing_list_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 h   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_order_info_uuid_order_info_uuid_fk;
       delivery          postgres    false    3853    242    229            �           2606    35643    users hr_user_department    FK CONSTRAINT     ~   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT hr_user_department FOREIGN KEY (department_uuid) REFERENCES hr.department(uuid);
 >   ALTER TABLE ONLY hr.users DROP CONSTRAINT hr_user_department;
       hr          postgres    false    3861    249    231            �           2606    35648 <   policy_and_notice policy_and_notice_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY hr.policy_and_notice
    ADD CONSTRAINT policy_and_notice_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 b   ALTER TABLE ONLY hr.policy_and_notice DROP CONSTRAINT policy_and_notice_created_by_users_uuid_fk;
       hr          postgres    false    251    3823    231            �           2606    35653 0   users users_designation_uuid_designation_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT users_designation_uuid_designation_uuid_fk FOREIGN KEY (designation_uuid) REFERENCES hr.designation(uuid);
 V   ALTER TABLE ONLY hr.users DROP CONSTRAINT users_designation_uuid_designation_uuid_fk;
       hr          postgres    false    250    231    3865            �           2606    35658 "   info info_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 M   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_created_by_users_uuid_fk;
       lab_dip          postgres    false    231    252    3823            �           2606    35663 ,   info info_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 W   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_order_info_uuid_order_info_uuid_fk;
       lab_dip          postgres    false    3853    252    242            �           2606    35668 3   info info_thread_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_thread_order_info_uuid_order_info_uuid_fk FOREIGN KEY (thread_order_info_uuid) REFERENCES thread.order_info(uuid);
 ^   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_thread_order_info_uuid_order_info_uuid_fk;
       lab_dip          postgres    false    3941    252    293            �           2606    35673 &   recipe recipe_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe
    ADD CONSTRAINT recipe_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 Q   ALTER TABLE ONLY lab_dip.recipe DROP CONSTRAINT recipe_created_by_users_uuid_fk;
       lab_dip          postgres    false    3823    254    231            �           2606    35678 4   recipe_entry recipe_entry_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe_entry
    ADD CONSTRAINT recipe_entry_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 _   ALTER TABLE ONLY lab_dip.recipe_entry DROP CONSTRAINT recipe_entry_material_uuid_info_uuid_fk;
       lab_dip          postgres    false    3881    260    255            �           2606    35683 4   recipe_entry recipe_entry_recipe_uuid_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe_entry
    ADD CONSTRAINT recipe_entry_recipe_uuid_recipe_uuid_fk FOREIGN KEY (recipe_uuid) REFERENCES lab_dip.recipe(uuid);
 _   ALTER TABLE ONLY lab_dip.recipe_entry DROP CONSTRAINT recipe_entry_recipe_uuid_recipe_uuid_fk;
       lab_dip          postgres    false    255    3873    254            �           2606    35688 ,   recipe recipe_lab_dip_info_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe
    ADD CONSTRAINT recipe_lab_dip_info_uuid_info_uuid_fk FOREIGN KEY (lab_dip_info_uuid) REFERENCES lab_dip.info(uuid);
 W   ALTER TABLE ONLY lab_dip.recipe DROP CONSTRAINT recipe_lab_dip_info_uuid_info_uuid_fk;
       lab_dip          postgres    false    254    3871    252            �           2606    35693 2   shade_recipe shade_recipe_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.shade_recipe
    ADD CONSTRAINT shade_recipe_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ]   ALTER TABLE ONLY lab_dip.shade_recipe DROP CONSTRAINT shade_recipe_created_by_users_uuid_fk;
       lab_dip          postgres    false    258    3823    231            �           2606    35698 @   shade_recipe_entry shade_recipe_entry_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.shade_recipe_entry
    ADD CONSTRAINT shade_recipe_entry_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 k   ALTER TABLE ONLY lab_dip.shade_recipe_entry DROP CONSTRAINT shade_recipe_entry_material_uuid_info_uuid_fk;
       lab_dip          postgres    false    259    3881    260            �           2606    35703 L   shade_recipe_entry shade_recipe_entry_shade_recipe_uuid_shade_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.shade_recipe_entry
    ADD CONSTRAINT shade_recipe_entry_shade_recipe_uuid_shade_recipe_uuid_fk FOREIGN KEY (shade_recipe_uuid) REFERENCES lab_dip.shade_recipe(uuid);
 w   ALTER TABLE ONLY lab_dip.shade_recipe_entry DROP CONSTRAINT shade_recipe_entry_shade_recipe_uuid_shade_recipe_uuid_fk;
       lab_dip          postgres    false    259    258    3877            �           2606    35708 "   info info_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY material.info DROP CONSTRAINT info_created_by_users_uuid_fk;
       material          postgres    false    231    260    3823            �           2606    35713 &   info info_section_uuid_section_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_section_uuid_section_uuid_fk FOREIGN KEY (section_uuid) REFERENCES material.section(uuid);
 R   ALTER TABLE ONLY material.info DROP CONSTRAINT info_section_uuid_section_uuid_fk;
       material          postgres    false    261    3883    260            �           2606    35718     info info_type_uuid_type_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_type_uuid_type_uuid_fk FOREIGN KEY (type_uuid) REFERENCES material.type(uuid);
 L   ALTER TABLE ONLY material.info DROP CONSTRAINT info_type_uuid_type_uuid_fk;
       material          postgres    false    3891    260    265            �           2606    35723 (   section section_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.section
    ADD CONSTRAINT section_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY material.section DROP CONSTRAINT section_created_by_users_uuid_fk;
       material          postgres    false    3823    261    231            �           2606    35728 &   stock stock_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock
    ADD CONSTRAINT stock_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 R   ALTER TABLE ONLY material.stock DROP CONSTRAINT stock_material_uuid_info_uuid_fk;
       material          postgres    false    3881    260    262            �           2606    35733 2   stock_to_sfg stock_to_sfg_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_created_by_users_uuid_fk;
       material          postgres    false    231    263    3823            �           2606    35738 4   stock_to_sfg stock_to_sfg_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 `   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_material_uuid_info_uuid_fk;
       material          postgres    false    263    260    3881            �           2606    35743 >   stock_to_sfg stock_to_sfg_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES zipper.order_entry(uuid);
 j   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_order_entry_uuid_order_entry_uuid_fk;
       material          postgres    false    240    3851    263            �           2606    35748     trx trx_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.trx
    ADD CONSTRAINT trx_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 L   ALTER TABLE ONLY material.trx DROP CONSTRAINT trx_created_by_users_uuid_fk;
       material          postgres    false    264    3823    231            �           2606    35753 "   trx trx_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.trx
    ADD CONSTRAINT trx_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 N   ALTER TABLE ONLY material.trx DROP CONSTRAINT trx_material_uuid_info_uuid_fk;
       material          postgres    false    260    3881    264            �           2606    35758 "   type type_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.type
    ADD CONSTRAINT type_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY material.type DROP CONSTRAINT type_created_by_users_uuid_fk;
       material          postgres    false    265    231    3823            �           2606    35763 "   used used_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.used
    ADD CONSTRAINT used_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY material.used DROP CONSTRAINT used_created_by_users_uuid_fk;
       material          postgres    false    266    231    3823            �           2606    35768 $   used used_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.used
    ADD CONSTRAINT used_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 P   ALTER TABLE ONLY material.used DROP CONSTRAINT used_material_uuid_info_uuid_fk;
       material          postgres    false    260    3881    266            �           2606    35773 $   buyer buyer_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.buyer
    ADD CONSTRAINT buyer_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY public.buyer DROP CONSTRAINT buyer_created_by_users_uuid_fk;
       public          postgres    false    231    232    3823            �           2606    35778 (   factory factory_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_created_by_users_uuid_fk;
       public          postgres    false    3823    233    231            �           2606    35783 (   factory factory_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 R   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_party_uuid_party_uuid_fk;
       public          postgres    false    236    233    3843            �           2606    35788 (   machine machine_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.machine
    ADD CONSTRAINT machine_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY public.machine DROP CONSTRAINT machine_created_by_users_uuid_fk;
       public          postgres    false    3823    267    231            �           2606    35793 ,   marketing marketing_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 V   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_created_by_users_uuid_fk;
       public          postgres    false    234    3823    231            �           2606    35798 +   marketing marketing_user_uuid_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_user_uuid_users_uuid_fk FOREIGN KEY (user_uuid) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_user_uuid_users_uuid_fk;
       public          postgres    false    3823    234    231            �           2606    35803 2   merchandiser merchandiser_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 \   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_created_by_users_uuid_fk;
       public          postgres    false    231    3823    235            �           2606    35808 2   merchandiser merchandiser_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 \   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_party_uuid_party_uuid_fk;
       public          postgres    false    3843    235    236            �           2606    35813 $   party party_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.party
    ADD CONSTRAINT party_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY public.party DROP CONSTRAINT party_created_by_users_uuid_fk;
       public          postgres    false    231    236    3823            �           2606    35818 0   description description_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.description
    ADD CONSTRAINT description_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 \   ALTER TABLE ONLY purchase.description DROP CONSTRAINT description_created_by_users_uuid_fk;
       purchase          postgres    false    231    3823    270            �           2606    35823 2   description description_vendor_uuid_vendor_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.description
    ADD CONSTRAINT description_vendor_uuid_vendor_uuid_fk FOREIGN KEY (vendor_uuid) REFERENCES purchase.vendor(uuid);
 ^   ALTER TABLE ONLY purchase.description DROP CONSTRAINT description_vendor_uuid_vendor_uuid_fk;
       purchase          postgres    false    3903    270    272            �           2606    35828 &   entry entry_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.entry
    ADD CONSTRAINT entry_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 R   ALTER TABLE ONLY purchase.entry DROP CONSTRAINT entry_material_uuid_info_uuid_fk;
       purchase          postgres    false    271    260    3881            �           2606    35833 9   entry entry_purchase_description_uuid_description_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.entry
    ADD CONSTRAINT entry_purchase_description_uuid_description_uuid_fk FOREIGN KEY (purchase_description_uuid) REFERENCES purchase.description(uuid);
 e   ALTER TABLE ONLY purchase.entry DROP CONSTRAINT entry_purchase_description_uuid_description_uuid_fk;
       purchase          postgres    false    3899    271    270            �           2606    35838 &   vendor vendor_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.vendor
    ADD CONSTRAINT vendor_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY purchase.vendor DROP CONSTRAINT vendor_created_by_users_uuid_fk;
       purchase          postgres    false    272    3823    231            �           2606    35843 6   assembly_stock assembly_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.assembly_stock
    ADD CONSTRAINT assembly_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 `   ALTER TABLE ONLY slider.assembly_stock DROP CONSTRAINT assembly_stock_created_by_users_uuid_fk;
       slider          postgres    false    231    273    3823            �           2606    35848 B   coloring_transaction coloring_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 l   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_created_by_users_uuid_fk;
       slider          postgres    false    3823    231    274            �           2606    35853 L   coloring_transaction coloring_transaction_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 v   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_order_info_uuid_order_info_uuid_fk;
       slider          postgres    false    274    3853    242            �           2606    35858 B   coloring_transaction coloring_transaction_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 l   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_stock_uuid_stock_uuid_fk;
       slider          postgres    false    3847    274    238            �           2606    35863 3   die_casting die_casting_end_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_end_type_properties_uuid_fk FOREIGN KEY (end_type) REFERENCES public.properties(uuid);
 ]   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_end_type_properties_uuid_fk;
       slider          postgres    false    3845    237    275            �           2606    35868 /   die_casting die_casting_item_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_item_properties_uuid_fk FOREIGN KEY (item) REFERENCES public.properties(uuid);
 Y   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_item_properties_uuid_fk;
       slider          postgres    false    3845    237    275            �           2606    35873 4   die_casting die_casting_logo_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_logo_type_properties_uuid_fk FOREIGN KEY (logo_type) REFERENCES public.properties(uuid);
 ^   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_logo_type_properties_uuid_fk;
       slider          postgres    false    3845    275    237            �           2606    35878 F   die_casting_production die_casting_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 p   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_created_by_users_uuid_fk;
       slider          postgres    false    276    231    3823            �           2606    35883 R   die_casting_production die_casting_production_die_casting_uuid_die_casting_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_die_casting_uuid_die_casting_uuid_fk FOREIGN KEY (die_casting_uuid) REFERENCES slider.die_casting(uuid);
 |   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_die_casting_uuid_die_casting_uuid_fk;
       slider          postgres    false    3909    276    275            �           2606    35888 V   die_casting_production die_casting_production_order_description_uuid_order_description    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_order_description_uuid_order_description FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 �   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_order_description_uuid_order_description;
       slider          postgres    false    239    276    3849            �           2606    35893 6   die_casting die_casting_puller_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_puller_type_properties_uuid_fk FOREIGN KEY (puller_type) REFERENCES public.properties(uuid);
 `   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_puller_type_properties_uuid_fk;
       slider          postgres    false    237    275    3845            �           2606    35898 <   die_casting die_casting_slider_body_shape_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_slider_body_shape_properties_uuid_fk FOREIGN KEY (slider_body_shape) REFERENCES public.properties(uuid);
 f   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_slider_body_shape_properties_uuid_fk;
       slider          postgres    false    237    275    3845            �           2606    35903 6   die_casting die_casting_slider_link_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_slider_link_properties_uuid_fk FOREIGN KEY (slider_link) REFERENCES public.properties(uuid);
 `   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_slider_link_properties_uuid_fk;
       slider          postgres    false    3845    275    237            �           2606    35908 ]   die_casting_to_assembly_stock die_casting_to_assembly_stock_assembly_stock_uuid_assembly_stoc    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock
    ADD CONSTRAINT die_casting_to_assembly_stock_assembly_stock_uuid_assembly_stoc FOREIGN KEY (assembly_stock_uuid) REFERENCES slider.assembly_stock(uuid);
 �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock DROP CONSTRAINT die_casting_to_assembly_stock_assembly_stock_uuid_assembly_stoc;
       slider          postgres    false    3905    273    277            �           2606    35913 T   die_casting_to_assembly_stock die_casting_to_assembly_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock
    ADD CONSTRAINT die_casting_to_assembly_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ~   ALTER TABLE ONLY slider.die_casting_to_assembly_stock DROP CONSTRAINT die_casting_to_assembly_stock_created_by_users_uuid_fk;
       slider          postgres    false    277    231    3823            �           2606    35918 H   die_casting_transaction die_casting_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 r   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_created_by_users_uuid_fk;
       slider          postgres    false    231    3823    278            �           2606    35923 T   die_casting_transaction die_casting_transaction_die_casting_uuid_die_casting_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_die_casting_uuid_die_casting_uuid_fk FOREIGN KEY (die_casting_uuid) REFERENCES slider.die_casting(uuid);
 ~   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_die_casting_uuid_die_casting_uuid_fk;
       slider          postgres    false    275    3909    278            �           2606    35928 H   die_casting_transaction die_casting_transaction_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 r   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_stock_uuid_stock_uuid_fk;
       slider          postgres    false    238    278    3847            �           2606    35933 8   die_casting die_casting_zipper_number_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_zipper_number_properties_uuid_fk FOREIGN KEY (zipper_number) REFERENCES public.properties(uuid);
 b   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_zipper_number_properties_uuid_fk;
       slider          postgres    false    275    237    3845            �           2606    35938 .   production production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.production
    ADD CONSTRAINT production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 X   ALTER TABLE ONLY slider.production DROP CONSTRAINT production_created_by_users_uuid_fk;
       slider          postgres    false    279    231    3823            �           2606    35943 .   production production_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.production
    ADD CONSTRAINT production_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 X   ALTER TABLE ONLY slider.production DROP CONSTRAINT production_stock_uuid_stock_uuid_fk;
       slider          postgres    false    238    3847    279            �           2606    35948 <   stock stock_order_description_uuid_order_description_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.stock
    ADD CONSTRAINT stock_order_description_uuid_order_description_uuid_fk FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 f   ALTER TABLE ONLY slider.stock DROP CONSTRAINT stock_order_description_uuid_order_description_uuid_fk;
       slider          postgres    false    239    238    3849            �           2606    35953 B   transaction transaction_assembly_stock_uuid_assembly_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_assembly_stock_uuid_assembly_stock_uuid_fk FOREIGN KEY (assembly_stock_uuid) REFERENCES slider.assembly_stock(uuid);
 l   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_assembly_stock_uuid_assembly_stock_uuid_fk;
       slider          postgres    false    280    273    3905            �           2606    35958 0   transaction transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 Z   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_created_by_users_uuid_fk;
       slider          postgres    false    231    3823    280                        2606    35963 0   transaction transaction_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 Z   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_stock_uuid_stock_uuid_fk;
       slider          postgres    false    3847    280    238                       2606    35968 <   trx_against_stock trx_against_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.trx_against_stock
    ADD CONSTRAINT trx_against_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 f   ALTER TABLE ONLY slider.trx_against_stock DROP CONSTRAINT trx_against_stock_created_by_users_uuid_fk;
       slider          postgres    false    231    281    3823                       2606    35973 H   trx_against_stock trx_against_stock_die_casting_uuid_die_casting_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.trx_against_stock
    ADD CONSTRAINT trx_against_stock_die_casting_uuid_die_casting_uuid_fk FOREIGN KEY (die_casting_uuid) REFERENCES slider.die_casting(uuid);
 r   ALTER TABLE ONLY slider.trx_against_stock DROP CONSTRAINT trx_against_stock_die_casting_uuid_die_casting_uuid_fk;
       slider          postgres    false    281    275    3909                       2606    35978 +   batch batch_coning_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_coning_created_by_users_uuid_fk FOREIGN KEY (coning_created_by) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_coning_created_by_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    35983 $   batch batch_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_created_by_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    35988 +   batch batch_dyeing_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_dyeing_created_by_users_uuid_fk FOREIGN KEY (dyeing_created_by) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_dyeing_created_by_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    35993 )   batch batch_dyeing_operator_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_dyeing_operator_users_uuid_fk FOREIGN KEY (dyeing_operator) REFERENCES hr.users(uuid);
 S   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_dyeing_operator_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    35998 +   batch batch_dyeing_supervisor_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_dyeing_supervisor_users_uuid_fk FOREIGN KEY (dyeing_supervisor) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_dyeing_supervisor_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    36003 0   batch_entry batch_entry_batch_uuid_batch_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry
    ADD CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk FOREIGN KEY (batch_uuid) REFERENCES thread.batch(uuid);
 Z   ALTER TABLE ONLY thread.batch_entry DROP CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk;
       thread          postgres    false    284    3923    283                       2606    36008 <   batch_entry batch_entry_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry
    ADD CONSTRAINT batch_entry_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES thread.order_entry(uuid);
 f   ALTER TABLE ONLY thread.batch_entry DROP CONSTRAINT batch_entry_order_entry_uuid_order_entry_uuid_fk;
       thread          postgres    false    284    3939    291                       2606    36013 R   batch_entry_production batch_entry_production_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_production
    ADD CONSTRAINT batch_entry_production_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES thread.batch_entry(uuid);
 |   ALTER TABLE ONLY thread.batch_entry_production DROP CONSTRAINT batch_entry_production_batch_entry_uuid_batch_entry_uuid_fk;
       thread          postgres    false    285    3925    284                       2606    36018 F   batch_entry_production batch_entry_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_production
    ADD CONSTRAINT batch_entry_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 p   ALTER TABLE ONLY thread.batch_entry_production DROP CONSTRAINT batch_entry_production_created_by_users_uuid_fk;
       thread          postgres    false    285    3823    231                       2606    36023 D   batch_entry_trx batch_entry_trx_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_trx
    ADD CONSTRAINT batch_entry_trx_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES thread.batch_entry(uuid);
 n   ALTER TABLE ONLY thread.batch_entry_trx DROP CONSTRAINT batch_entry_trx_batch_entry_uuid_batch_entry_uuid_fk;
       thread          postgres    false    286    3925    284                       2606    36028 8   batch_entry_trx batch_entry_trx_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_trx
    ADD CONSTRAINT batch_entry_trx_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 b   ALTER TABLE ONLY thread.batch_entry_trx DROP CONSTRAINT batch_entry_trx_created_by_users_uuid_fk;
       thread          postgres    false    286    3823    231                       2606    36033 (   batch batch_lab_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_lab_created_by_users_uuid_fk FOREIGN KEY (lab_created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_lab_created_by_users_uuid_fk;
       thread          postgres    false    283    3823    231            	           2606    36038 (   batch batch_machine_uuid_machine_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_machine_uuid_machine_uuid_fk FOREIGN KEY (machine_uuid) REFERENCES public.machine(uuid);
 R   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_machine_uuid_machine_uuid_fk;
       thread          postgres    false    283    3895    267            
           2606    36043 !   batch batch_pass_by_users_uuid_fk    FK CONSTRAINT     ~   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_pass_by_users_uuid_fk FOREIGN KEY (pass_by) REFERENCES hr.users(uuid);
 K   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_pass_by_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    36048 /   batch batch_yarn_issue_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_yarn_issue_created_by_users_uuid_fk FOREIGN KEY (yarn_issue_created_by) REFERENCES hr.users(uuid);
 Y   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_yarn_issue_created_by_users_uuid_fk;
       thread          postgres    false    283    3823    231                       2606    36053 '   challan challan_assign_to_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_assign_to_users_uuid_fk FOREIGN KEY (assign_to) REFERENCES hr.users(uuid);
 Q   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_assign_to_users_uuid_fk;
       thread          postgres    false    287    3823    231                       2606    36058 (   challan challan_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_created_by_users_uuid_fk;
       thread          postgres    false    287    3823    231                       2606    36063 8   challan_entry challan_entry_challan_uuid_challan_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk FOREIGN KEY (challan_uuid) REFERENCES thread.challan(uuid);
 b   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk;
       thread          postgres    false    288    3931    287                       2606    36068 4   challan_entry challan_entry_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_created_by_users_uuid_fk;
       thread          postgres    false    288    3823    231                       2606    36073 @   challan_entry challan_entry_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES thread.order_entry(uuid);
 j   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_order_entry_uuid_order_entry_uuid_fk;
       thread          postgres    false    288    291    3939                       2606    36078 2   challan challan_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES thread.order_info(uuid);
 \   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_order_info_uuid_order_info_uuid_fk;
       thread          postgres    false    287    3941    293                       2606    36083 2   count_length count_length_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.count_length
    ADD CONSTRAINT count_length_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 \   ALTER TABLE ONLY thread.count_length DROP CONSTRAINT count_length_created_by_users_uuid_fk;
       thread          postgres    false    289    3823    231                       2606    36088 4   dyes_category dyes_category_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.dyes_category
    ADD CONSTRAINT dyes_category_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY thread.dyes_category DROP CONSTRAINT dyes_category_created_by_users_uuid_fk;
       thread          postgres    false    290    3823    231                       2606    36093 >   order_entry order_entry_count_length_uuid_count_length_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_count_length_uuid_count_length_uuid_fk FOREIGN KEY (count_length_uuid) REFERENCES thread.count_length(uuid);
 h   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_count_length_uuid_count_length_uuid_fk;
       thread          postgres    false    291    3935    289                       2606    36098 0   order_entry order_entry_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 Z   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_created_by_users_uuid_fk;
       thread          postgres    false    291    3823    231                       2606    36103 :   order_entry order_entry_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES thread.order_info(uuid);
 d   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_order_info_uuid_order_info_uuid_fk;
       thread          postgres    false    291    3941    293                       2606    36108 2   order_entry order_entry_recipe_uuid_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_recipe_uuid_recipe_uuid_fk FOREIGN KEY (recipe_uuid) REFERENCES lab_dip.recipe(uuid);
 \   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_recipe_uuid_recipe_uuid_fk;
       thread          postgres    false    291    3873    254                       2606    36113 .   order_info order_info_buyer_uuid_buyer_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk FOREIGN KEY (buyer_uuid) REFERENCES public.buyer(uuid);
 X   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk;
       thread          postgres    false    293    3827    232                       2606    36118 .   order_info order_info_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 X   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_created_by_users_uuid_fk;
       thread          postgres    false    293    3823    231                        2606    36123 2   order_info order_info_factory_uuid_factory_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_factory_uuid_factory_uuid_fk FOREIGN KEY (factory_uuid) REFERENCES public.factory(uuid);
 \   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_factory_uuid_factory_uuid_fk;
       thread          postgres    false    293    3831    233            !           2606    36128 6   order_info order_info_marketing_uuid_marketing_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk FOREIGN KEY (marketing_uuid) REFERENCES public.marketing(uuid);
 `   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk;
       thread          postgres    false    293    3835    234            "           2606    36133 <   order_info order_info_merchandiser_uuid_merchandiser_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk FOREIGN KEY (merchandiser_uuid) REFERENCES public.merchandiser(uuid);
 f   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk;
       thread          postgres    false    293    3839    235            #           2606    36138 .   order_info order_info_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 X   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_party_uuid_party_uuid_fk;
       thread          postgres    false    293    3843    236            $           2606    36143 *   programs programs_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_created_by_users_uuid_fk;
       thread          postgres    false    294    3823    231            %           2606    36148 :   programs programs_dyes_category_uuid_dyes_category_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_dyes_category_uuid_dyes_category_uuid_fk FOREIGN KEY (dyes_category_uuid) REFERENCES thread.dyes_category(uuid);
 d   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_dyes_category_uuid_dyes_category_uuid_fk;
       thread          postgres    false    294    3937    290            &           2606    36153 ,   programs programs_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 V   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_material_uuid_info_uuid_fk;
       thread          postgres    false    294    3881    260            '           2606    36158 $   batch batch_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch
    ADD CONSTRAINT batch_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY zipper.batch DROP CONSTRAINT batch_created_by_users_uuid_fk;
       zipper          postgres    false    295    3823    231            )           2606    36163 0   batch_entry batch_entry_batch_uuid_batch_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_entry
    ADD CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk FOREIGN KEY (batch_uuid) REFERENCES zipper.batch(uuid);
 Z   ALTER TABLE ONLY zipper.batch_entry DROP CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk;
       zipper          postgres    false    296    3945    295            *           2606    36168 ,   batch_entry batch_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_entry
    ADD CONSTRAINT batch_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 V   ALTER TABLE ONLY zipper.batch_entry DROP CONSTRAINT batch_entry_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    296    3855    243            (           2606    36173 (   batch batch_machine_uuid_machine_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch
    ADD CONSTRAINT batch_machine_uuid_machine_uuid_fk FOREIGN KEY (machine_uuid) REFERENCES public.machine(uuid);
 R   ALTER TABLE ONLY zipper.batch DROP CONSTRAINT batch_machine_uuid_machine_uuid_fk;
       zipper          postgres    false    3895    295    267            +           2606    36178 F   batch_production batch_production_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_production
    ADD CONSTRAINT batch_production_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES zipper.batch_entry(uuid);
 p   ALTER TABLE ONLY zipper.batch_production DROP CONSTRAINT batch_production_batch_entry_uuid_batch_entry_uuid_fk;
       zipper          postgres    false    296    3947    298            ,           2606    36183 :   batch_production batch_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_production
    ADD CONSTRAINT batch_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 d   ALTER TABLE ONLY zipper.batch_production DROP CONSTRAINT batch_production_created_by_users_uuid_fk;
       zipper          postgres    false    298    3823    231            -           2606    36188 D   dyed_tape_transaction dyed_tape_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction
    ADD CONSTRAINT dyed_tape_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 n   ALTER TABLE ONLY zipper.dyed_tape_transaction DROP CONSTRAINT dyed_tape_transaction_created_by_users_uuid_fk;
       zipper          postgres    false    299    3823    231            /           2606    36193 Z   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_created_by_users_uuid_fk;
       zipper          postgres    false    300    3823    231            0           2606    36198 `   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_order_description_uuid_order_d    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_order_description_uuid_order_d FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_order_description_uuid_order_d;
       zipper          postgres    false    300    3849    239            1           2606    36203 `   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_tape_coil_uuid_tape_coil_uuid_    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_tape_coil_uuid_tape_coil_uuid_ FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_tape_coil_uuid_tape_coil_uuid_;
       zipper          postgres    false    300    3857    244            .           2606    36208 U   dyed_tape_transaction dyed_tape_transaction_order_description_uuid_order_description_    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction
    ADD CONSTRAINT dyed_tape_transaction_order_description_uuid_order_description_ FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
    ALTER TABLE ONLY zipper.dyed_tape_transaction DROP CONSTRAINT dyed_tape_transaction_order_description_uuid_order_description_;
       zipper          postgres    false    299    3849    239            2           2606    36213 H   dying_batch_entry dying_batch_entry_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dying_batch_entry
    ADD CONSTRAINT dying_batch_entry_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES zipper.batch_entry(uuid);
 r   ALTER TABLE ONLY zipper.dying_batch_entry DROP CONSTRAINT dying_batch_entry_batch_entry_uuid_batch_entry_uuid_fk;
       zipper          postgres    false    302    3947    296            3           2606    36218 H   dying_batch_entry dying_batch_entry_dying_batch_uuid_dying_batch_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dying_batch_entry
    ADD CONSTRAINT dying_batch_entry_dying_batch_uuid_dying_batch_uuid_fk FOREIGN KEY (dying_batch_uuid) REFERENCES zipper.dying_batch(uuid);
 r   ALTER TABLE ONLY zipper.dying_batch_entry DROP CONSTRAINT dying_batch_entry_dying_batch_uuid_dying_batch_uuid_fk;
       zipper          postgres    false    302    3955    301            4           2606    36223 f   material_trx_against_order_description material_trx_against_order_description_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 �   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_created_by_users_uuid_fk;
       zipper          postgres    false    304    3823    231            5           2606    36228 f   material_trx_against_order_description material_trx_against_order_description_material_uuid_info_uuid_    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_material_uuid_info_uuid_ FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 �   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_material_uuid_info_uuid_;
       zipper          postgres    false    260    3881    304            6           2606    36233 f   material_trx_against_order_description material_trx_against_order_description_order_description_uuid_o    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_order_description_uuid_o FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 �   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_order_description_uuid_o;
       zipper          postgres    false    239    304    3849            �           2606    36238 E   order_description order_description_bottom_stopper_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_bottom_stopper_properties_uuid_fk FOREIGN KEY (bottom_stopper) REFERENCES public.properties(uuid);
 o   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_bottom_stopper_properties_uuid_fk;
       zipper          postgres    false    237    239    3845            �           2606    36243 D   order_description order_description_coloring_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_coloring_type_properties_uuid_fk FOREIGN KEY (coloring_type) REFERENCES public.properties(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_coloring_type_properties_uuid_fk;
       zipper          postgres    false    237    3845    239            �           2606    36248 <   order_description order_description_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 f   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_created_by_users_uuid_fk;
       zipper          postgres    false    239    231    3823            �           2606    36253 ?   order_description order_description_end_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_end_type_properties_uuid_fk FOREIGN KEY (end_type) REFERENCES public.properties(uuid);
 i   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_end_type_properties_uuid_fk;
       zipper          postgres    false    3845    237    239            �           2606    36258 ?   order_description order_description_end_user_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_end_user_properties_uuid_fk FOREIGN KEY (end_user) REFERENCES public.properties(uuid);
 i   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_end_user_properties_uuid_fk;
       zipper          postgres    false    239    3845    237            �           2606    36263 ;   order_description order_description_hand_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_hand_properties_uuid_fk FOREIGN KEY (hand) REFERENCES public.properties(uuid);
 e   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_hand_properties_uuid_fk;
       zipper          postgres    false    239    3845    237            �           2606    36268 ;   order_description order_description_item_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_item_properties_uuid_fk FOREIGN KEY (item) REFERENCES public.properties(uuid);
 e   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_item_properties_uuid_fk;
       zipper          postgres    false    239    237    3845            �           2606    36273 G   order_description order_description_light_preference_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_light_preference_properties_uuid_fk FOREIGN KEY (light_preference) REFERENCES public.properties(uuid);
 q   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_light_preference_properties_uuid_fk;
       zipper          postgres    false    3845    237    239            �           2606    36278 @   order_description order_description_lock_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_lock_type_properties_uuid_fk FOREIGN KEY (lock_type) REFERENCES public.properties(uuid);
 j   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_lock_type_properties_uuid_fk;
       zipper          postgres    false    239    237    3845            �           2606    36283 @   order_description order_description_logo_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_logo_type_properties_uuid_fk FOREIGN KEY (logo_type) REFERENCES public.properties(uuid);
 j   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_logo_type_properties_uuid_fk;
       zipper          postgres    false    237    239    3845            �           2606    36288 D   order_description order_description_nylon_stopper_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_nylon_stopper_properties_uuid_fk FOREIGN KEY (nylon_stopper) REFERENCES public.properties(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_nylon_stopper_properties_uuid_fk;
       zipper          postgres    false    237    239    3845            �           2606    36293 F   order_description order_description_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 p   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_order_info_uuid_order_info_uuid_fk;
       zipper          postgres    false    242    239    3853            �           2606    36298 C   order_description order_description_puller_color_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_puller_color_properties_uuid_fk FOREIGN KEY (puller_color) REFERENCES public.properties(uuid);
 m   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_puller_color_properties_uuid_fk;
       zipper          postgres    false    239    3845    237            �           2606    36303 B   order_description order_description_puller_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_puller_type_properties_uuid_fk FOREIGN KEY (puller_type) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_puller_type_properties_uuid_fk;
       zipper          postgres    false    237    239    3845            �           2606    36308 H   order_description order_description_slider_body_shape_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_slider_body_shape_properties_uuid_fk FOREIGN KEY (slider_body_shape) REFERENCES public.properties(uuid);
 r   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_slider_body_shape_properties_uuid_fk;
       zipper          postgres    false    3845    237    239            �           2606    36313 B   order_description order_description_slider_link_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_slider_link_properties_uuid_fk FOREIGN KEY (slider_link) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_slider_link_properties_uuid_fk;
       zipper          postgres    false    239    237    3845            �           2606    36318 =   order_description order_description_slider_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_slider_properties_uuid_fk FOREIGN KEY (slider) REFERENCES public.properties(uuid);
 g   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_slider_properties_uuid_fk;
       zipper          postgres    false    237    239    3845            �           2606    36323 D   order_description order_description_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    3857    244    239            �           2606    36328 B   order_description order_description_teeth_color_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_teeth_color_properties_uuid_fk FOREIGN KEY (teeth_color) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_teeth_color_properties_uuid_fk;
       zipper          postgres    false    239    3845    237            �           2606    36333 A   order_description order_description_teeth_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_teeth_type_properties_uuid_fk FOREIGN KEY (teeth_type) REFERENCES public.properties(uuid);
 k   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_teeth_type_properties_uuid_fk;
       zipper          postgres    false    3845    239    237            �           2606    36338 B   order_description order_description_top_stopper_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_top_stopper_properties_uuid_fk FOREIGN KEY (top_stopper) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_top_stopper_properties_uuid_fk;
       zipper          postgres    false    239    237    3845            �           2606    36343 D   order_description order_description_zipper_number_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_zipper_number_properties_uuid_fk FOREIGN KEY (zipper_number) REFERENCES public.properties(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_zipper_number_properties_uuid_fk;
       zipper          postgres    false    239    237    3845            �           2606    36348 H   order_entry order_entry_order_description_uuid_order_description_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_entry
    ADD CONSTRAINT order_entry_order_description_uuid_order_description_uuid_fk FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 r   ALTER TABLE ONLY zipper.order_entry DROP CONSTRAINT order_entry_order_description_uuid_order_description_uuid_fk;
       zipper          postgres    false    3849    239    240            �           2606    36353 .   order_info order_info_buyer_uuid_buyer_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk FOREIGN KEY (buyer_uuid) REFERENCES public.buyer(uuid);
 X   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk;
       zipper          postgres    false    232    242    3827            �           2606    36358 2   order_info order_info_factory_uuid_factory_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_factory_uuid_factory_uuid_fk FOREIGN KEY (factory_uuid) REFERENCES public.factory(uuid);
 \   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_factory_uuid_factory_uuid_fk;
       zipper          postgres    false    242    233    3831            �           2606    36363 6   order_info order_info_marketing_uuid_marketing_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk FOREIGN KEY (marketing_uuid) REFERENCES public.marketing(uuid);
 `   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk;
       zipper          postgres    false    3835    234    242            �           2606    36368 <   order_info order_info_merchandiser_uuid_merchandiser_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk FOREIGN KEY (merchandiser_uuid) REFERENCES public.merchandiser(uuid);
 f   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk;
       zipper          postgres    false    235    242    3839            �           2606    36373 .   order_info order_info_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 X   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_party_uuid_party_uuid_fk;
       zipper          postgres    false    242    3843    236            7           2606    36378 *   planning planning_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.planning
    ADD CONSTRAINT planning_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY zipper.planning DROP CONSTRAINT planning_created_by_users_uuid_fk;
       zipper          postgres    false    3823    231    305            8           2606    36383 <   planning_entry planning_entry_planning_week_planning_week_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.planning_entry
    ADD CONSTRAINT planning_entry_planning_week_planning_week_fk FOREIGN KEY (planning_week) REFERENCES zipper.planning(week);
 f   ALTER TABLE ONLY zipper.planning_entry DROP CONSTRAINT planning_entry_planning_week_planning_week_fk;
       zipper          postgres    false    305    3961    306            9           2606    36388 2   planning_entry planning_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.planning_entry
    ADD CONSTRAINT planning_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 \   ALTER TABLE ONLY zipper.planning_entry DROP CONSTRAINT planning_entry_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    306    243    3855            �           2606    36393 ,   sfg sfg_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg
    ADD CONSTRAINT sfg_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES zipper.order_entry(uuid);
 V   ALTER TABLE ONLY zipper.sfg DROP CONSTRAINT sfg_order_entry_uuid_order_entry_uuid_fk;
       zipper          postgres    false    243    240    3851            :           2606    36398 6   sfg_production sfg_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_production
    ADD CONSTRAINT sfg_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 `   ALTER TABLE ONLY zipper.sfg_production DROP CONSTRAINT sfg_production_created_by_users_uuid_fk;
       zipper          postgres    false    231    307    3823            ;           2606    36403 2   sfg_production sfg_production_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_production
    ADD CONSTRAINT sfg_production_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 \   ALTER TABLE ONLY zipper.sfg_production DROP CONSTRAINT sfg_production_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    243    307    3855            �           2606    36408 "   sfg sfg_recipe_uuid_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg
    ADD CONSTRAINT sfg_recipe_uuid_recipe_uuid_fk FOREIGN KEY (recipe_uuid) REFERENCES lab_dip.recipe(uuid);
 L   ALTER TABLE ONLY zipper.sfg DROP CONSTRAINT sfg_recipe_uuid_recipe_uuid_fk;
       zipper          postgres    false    243    3873    254            <           2606    36413 8   sfg_transaction sfg_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 b   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_created_by_users_uuid_fk;
       zipper          postgres    false    231    308    3823            =           2606    36418 4   sfg_transaction sfg_transaction_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 ^   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    3855    243    308            >           2606    36423 >   sfg_transaction sfg_transaction_slider_item_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_slider_item_uuid_stock_uuid_fk FOREIGN KEY (slider_item_uuid) REFERENCES slider.stock(uuid);
 h   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_slider_item_uuid_stock_uuid_fk;
       zipper          postgres    false    308    238    3847            �           2606    36428 ,   tape_coil tape_coil_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 V   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_created_by_users_uuid_fk;
       zipper          postgres    false    231    3823    244            �           2606    36433 0   tape_coil tape_coil_item_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_item_uuid_properties_uuid_fk FOREIGN KEY (item_uuid) REFERENCES public.properties(uuid);
 Z   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_item_uuid_properties_uuid_fk;
       zipper          postgres    false    244    237    3845            ?           2606    36438 B   tape_coil_production tape_coil_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_production
    ADD CONSTRAINT tape_coil_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 l   ALTER TABLE ONLY zipper.tape_coil_production DROP CONSTRAINT tape_coil_production_created_by_users_uuid_fk;
       zipper          postgres    false    309    3823    231            @           2606    36443 J   tape_coil_production tape_coil_production_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_production
    ADD CONSTRAINT tape_coil_production_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 t   ALTER TABLE ONLY zipper.tape_coil_production DROP CONSTRAINT tape_coil_production_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    244    309    3857            A           2606    36448 >   tape_coil_required tape_coil_required_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 h   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_created_by_users_uuid_fk;
       zipper          postgres    false    3823    231    310            B           2606    36453 F   tape_coil_required tape_coil_required_end_type_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_end_type_uuid_properties_uuid_fk FOREIGN KEY (end_type_uuid) REFERENCES public.properties(uuid);
 p   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_end_type_uuid_properties_uuid_fk;
       zipper          postgres    false    310    3845    237            C           2606    36458 B   tape_coil_required tape_coil_required_item_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_item_uuid_properties_uuid_fk FOREIGN KEY (item_uuid) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_item_uuid_properties_uuid_fk;
       zipper          postgres    false    310    237    3845            D           2606    36463 K   tape_coil_required tape_coil_required_nylon_stopper_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_nylon_stopper_uuid_properties_uuid_fk FOREIGN KEY (nylon_stopper_uuid) REFERENCES public.properties(uuid);
 u   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_nylon_stopper_uuid_properties_uuid_fk;
       zipper          postgres    false    3845    310    237            E           2606    36468 K   tape_coil_required tape_coil_required_zipper_number_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_zipper_number_uuid_properties_uuid_fk FOREIGN KEY (zipper_number_uuid) REFERENCES public.properties(uuid);
 u   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_zipper_number_uuid_properties_uuid_fk;
       zipper          postgres    false    310    237    3845            F           2606    36473 @   tape_coil_to_dyeing tape_coil_to_dyeing_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 j   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_created_by_users_uuid_fk;
       zipper          postgres    false    231    3823    311            G           2606    36478 S   tape_coil_to_dyeing tape_coil_to_dyeing_order_description_uuid_order_description_uu    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_order_description_uuid_order_description_uu FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 }   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_order_description_uuid_order_description_uu;
       zipper          postgres    false    239    3849    311            H           2606    36483 H   tape_coil_to_dyeing tape_coil_to_dyeing_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 r   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    244    3857    311            �           2606    36488 9   tape_coil tape_coil_zipper_number_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_zipper_number_uuid_properties_uuid_fk FOREIGN KEY (zipper_number_uuid) REFERENCES public.properties(uuid);
 c   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_zipper_number_uuid_properties_uuid_fk;
       zipper          postgres    false    3845    244    237            I           2606    36493 .   tape_trx tape_to_coil_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_to_coil_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 X   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_to_coil_created_by_users_uuid_fk;
       zipper          postgres    false    312    3823    231            J           2606    36498 6   tape_trx tape_to_coil_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_to_coil_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 `   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_to_coil_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    312    3857    244            K           2606    36503 *   tape_trx tape_trx_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_trx_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_trx_created_by_users_uuid_fk;
       zipper          postgres    false    3823    231    312            L           2606    36508 2   tape_trx tape_trx_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_trx_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 \   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_trx_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    312    3857    244            /      x������ � �      1      x������ � �      3      x������ � �      4      x������ � �      6      x������ � �      7      x������ � �      9      x������ � �      :      x������ � �      I      x�=�Y�$+E���!���a���QDd�uW��A��x�G�J��^���F:늯�NK��l}�u�)֓�1s�2��5�z���y���GL�X�{��\�:��}��&j7�>;�R�]�m����m�bg�Q?UZkՋ���\��i�N���ʙ��d�Cg/��^�(�[����.?ѩ�}|
��"V�����6v�V�������;��Қ�����!�vV�{�9��ö?-i-]�������6&Y=J$g_1��9����I�픑2?��K*����+�ܲ���g8͟��R�W}nk�j���4t�5���;i���FK���_��k��^{������8��Es�(���ї�cV_�v�F�9��9��7?�-�K(Z���4�G s�vm>�,2'�t���lf>��s��
$n4AogϿ�=G+���Fɖ
�_c� �����h�w��){M�ҩ�5����ZXU]%
�M�8�7��I�lKo���vZ{�$i �=r|�R��J:V������*zKE%����r��4�U�`���t���]6�X��rv>]���_��h�W1{}syz�)�3}z��mz 8� �RR[�^�d[i[���m4�rp��ȿ�5�^�,ϩ�4�4�%�k��*�vҜ>l��y��)���mj^U��a�ǿ�-5���	b�|�䤽�,@�#�R���c���T�6�� �Cov��ZSnkԇC���p�s��7�ơiu[>wr0�3U�-�:�-��h�#v{s{X����2aKj�'C͸F��UfY,~�'�~��r.��Y��V���������D1��ɮ�E�SO��&0�bTN~ng̀?�`D $�]{�ebr��5�4���,�S<�K����M�V5��8��g���s�o�A3Lay�?B�٤1��Ȧ
���i�c��Uꨧ�#��y�9�t|��O�UԜ�ܝ ���}�2G����a�|Wʧ ���͘��j�	t��蟊�q�]ߒ��/TY�d�z���O9���D���?����J�şu�n�-�a!�N���n��3�[�����z}^��=��Uy����ؽ�[գ����Sh!(�&��Z�Ƹ�%�T9�of~�-u��d��r�x�U�Ϯ�c}V:SD�܅�ѐ�'�;s���0�l (��3�4�aW�E�[��'���1���aEc18Ɣ���)�P���RwamC����Ѷ��\O���`�l)��=L��٧QC�jKkU���<�#MH�BX�s=-�uO��;k5zl�R��Y�\��9C�􅢏��>TC�Fc��Ԛ�o2���Ul���φ��̨��'�<o��`h6�Ԁ�B�K@Aw-Yo��Zߊ�d�ǟ�W��FX�������E�v�-X��r��qp��A=9�=ӯ"l��3����Nk#NL�����9�� =���p�<

����u�)XB�J~0[NI~K0F��wL�B���W��K=�C�3�]�U귏�îkz!#<�_�.�ey���ZuI��[���F
^��AG��3i��+S�z�h�hW���+.j��`2_/3����s�(���_Ŏ���_��.�\�����ٱՂda;S�7��r�"O�fH0�	9�L�lP������&ZQ$߹����P,\�pl�m�΋ca�8�r��9���U�R��c{Bb8ܭa����`���|�-kXAK����s����U��X�3�6��@2��'7�������AqZ]X6\Ӈs���vj?���$z���c��1<L�7�VǔU��cF`j�,`�/����e�����%r�?f��)=1cơjӃKf�#W��k�����������f�����Y����_,w2S��j�a�nt�i[�S8�΃�V,8��5?D���r<g��u�\w(aa�|Q�����:�~bj�V,h��[˃��#�Q� �ź�8m�����c����x2Ft�N��m&����n�S��!��_-��F�;cc�?jTW��l10�@t.�#zlz �_����Z�������Yl"y�[m9CAP�B5�7��7�Ό�G}��<s�a�ߪϾ��r����=���q+�IF�����
��%���_E4C���d$�H"�'�MH	�y^�'pY�]]8�3��c�q=W�*B��j���1�l�g��`2��G�`�2$(T2��/ |��T����'T��AX>�.�A`x$���|�5l�B1%��������O�*Z�#�!�8��UN�~E�q-����	���o\2҈3�R �x��X%�z�<�N�H��
��5a.	8�p�'-,#�3��;җ����У��j~z�Xq��*����g���Nar����Q�Xs@�n���ߙ�$a�(�r������@�sT�ɌHQ2�MVE"/�����M'�+�op��M�u*�3#����z�݀�O��(L�>�(��m��CX.ޯ �z,�^"�+2I� -�~��X�@o8��7�F�^Y��>q��Ø7�3��1��Z���#��*�����}㪘	�a!��4�a9%�|��PC]�u~FN�����}H8���$�0��u`^ȉn���g�(��L8:���w
+Y<$�]�3�h�m��t���;p��� A,b�+܍���}0�~+���q\��g2)?�P l�7�$=���bg�3t�<y��}R��4�~��`s����̉��!6�6����/bu���u3#��:i�W��Y'B���� �%�]1�8��GX����vZXA����Ed>���Fd�䟸��=�����7��J��+�=���rK�e�%UpĄ�Is�cpڷ"�9�����i��X!
%�\:d�	\+�)�hX\  ��C���k��s��O�����/&c�Z?!�^�[;�$���nߊ)f�!BX�֌��G���U����O�j�a���k�3��MN��ՆW$��=ޛ�P���`�-a��LH<'�O�$ݒ1��l>.6}�Q/�r�,�$ws4�Ȁ�lam�_a�H���E%��Sxi���m���&�X��
�J�Ģ�kHN����5���3��%�%��L֕SÊ�0-K��Yp�k�
��:�b���a�n�lu�o�n{��m�Y�d���f��%�X�<S��^ ��9h�m(n�W�Sg
1k����ʐ���$�@�	k�aCu����T,L���q�8q2��S�l��0�%�^w��d �4r%��{����<����C�lp2���L�b����˅D0� vƵ31�|�p8FYi��1w"��v���󫨟۽���.e��E!�T��;�@R��EfZ��@C����]K
Op{M�>j�If�p��q��MT�x�1�`���Q>�`��L����,�dR�XAO�8	��Nf�h5���C�(n���l[x�z&��὘n�����q{�>ZK��y�
8����x5�f%��I��[%gV؃�V�س���q��t�4���iln8��_��+��d�9$�1E@b�J���`e`1]qY�"μ�	YB�/����i#�lf��C�^�r�(!�誱��w ���jǇ[�Bz�M
�w��(����:YY2���n�����GC�>�E�!<$N�q�D1���>��H�	@, �sG���;�0�I� ���3q��ك.ގ7�;�f��CE�7�L���%��fFK��Ж�<�"#�o�iL*N�~�!~�<D��h@�d2;1K	�V�4|���R��x�6�覿�!°YGg@A�K��Vc����#f����*�!a�q����Y�庿]ׂ�k���cqO9�*��48}���_`�6fDNd�d�l���w�ׯ"Ύm���p�q�!.�Ӧ��BGW�om	���A���yl��G�7��z�̮����.��j�UA�����JY��L�ؓ.����R��؂"���C��mw���V�ߘ�퉇fP��qϊ����Z�	 �l 8�C�'(�8�7).[��\�`as����Jx祽��#>5̀�h����7����L�m�{�D��b@������H6p��2s��Ղb�7��V�������zy��q���M����q�I Q  [�� �aJ�W��Y1]d�4���~g�4>��YēQ��+d�f�3��G�.�l�t�������)P�pd��of,gX�̅YC/q�x����"a��%DV�k<΋� ^2*�)�ү�F��B5��0��z�	ESМ`�
���1�)':*ȡ'�5q�[�����=7���d$5�������Y@��?��2E��>�W���U,�����\X`y�������F�p��*و%���3��)��[�_�x-��d`\2Վ�P�kg	,��#��0bʹ90�|�j��)"�aH���q���
��	�ɞ"�|����	y��JJds��.`�OE�����7�2X�E$���'$8�&�p����� ,&?e�c�.nl}!��@������6� \��d9Ƹ�V<�>�&����B7.���c�*O���h���vѬ',�g-���irXz@2-W&��?X��N���;�O��I�$���Y+%������q���ƦMB!��0�7s�/$�t��9����$��a��5.+$^Ņ���ղ��2膿�#�"�d�"�3�p)"O�w|�+�q�(@�|�,��<Jʏ��L4[�� �`�z�F���|�d[�O|@�܎���Ir������G��n�Cw|r�	���Ӆ�ixg��Y�2�-)�W�� �=Ò��O4���Js9�z��A����n�M��c�����%��D�FIb1n8�	3`���|7]x+}*	 �T�@+�1��K�م����?�:�-����y�h�pw�%Κ���B@���(I���Y��Vg�9.`�㐍<���$XN$]I�\ص��BhG�_#��J2����d�_ܱ�Ąѱ�7^q�񾻇���0|�>�#^Q��A�X���;�$��N���vD�bS��k�����}���Pu������
�4���۸#�;%�!��8U�\���(9����O@5F�
 �6]��8��Kq�� d�dzM���;)$�6�)��v��n�B��U�)4.���$�LC���cփ��aa!:�Q�*2$�)���j�/���ﳠ<q�W����-N<^�c��!#^��JO{���n��N���m�=n	a���ʘ��/.�)�Mj�=g�/!Q�kaw�D	�b�ehkblᆖwaUؿ$v�%�ҒT " ����O�r�/>lP�^s\<|@�����
}�G �d����d|���A,�Qn�	�T�Exi�5+�+ֵ� �E�o|�c��G@�7+�$�U)ox�w'��H��>h�صԓH$p�).��x�ct +��������|Y2�<�rğ_�8t�O/F|HZY��	�Ӑ�y���!���ς�9��7K�P\��u�e�z�듯H��!
UN�Tv뿍��r\�QR�������݊ ��۠\+����D(�7>;t�v�i��)	<Ps@o��{�������`	���}��~�m��\:;�"E�����"d����Ԓ3���IB��u�B���S=���e�m�D�-Jδ~�)�X�`�.��L����Qm\dǫ���!&�ᔺ}���	�2���"���_%�I'^�°�F��/�a�ϛg���>���m��XQ������SR#��O*7���;O!�h		Þ�����D<�EO�_@���-�)y���Ը��9lĀ̄��z�t&$�3@)@q�.V���]�?��/.i9CE#�?9&�3��Q��V�k?�#H%��ܠ.����`Ÿ�	G!��o�)	���m�M�+8�e�����v�uvI���]�7Fn:�CJ��:.K,�׽������r@g2      K   e  x���Ks�@F���`9Yd����	�`�7�+��ڑ�4��&�1���*V�9�{?���ơ���d-�sP2Q�r�[(KH!�F��G���K�t��0]ٌU�����X	�Q���L�O�<؉ �}�FPB:A�`x������.}�o}��Y���XB*Q5��#�JV0��;U� g4�d�&A��m"wN��-_�����Fv�-`fI���ZR)�����׹+0�/״���$~	荨��6.��%������b73�`]���CV^7��I'�x�̆#��FU�����o�O'J�������o���+���;ᴿ81�Xq)�j'!s\<̠u��ĩ���k�.��1ֻG�Ʃ���rj ��|Ǌ�ZQ�1J+Åi荩y8�`4:���6c�����w]o7|�ԓ �Yz�ۇ��-�x�l�Q���ze���J2k�d����|,a��Y������ZeE�SZ�Q%����M�7�И	��FҐkV�wz~T�����- �"�u�꽙b=콹��J�U�ڗ~x~s������~�"�k�
tgHhG��#ʛsף�z��(����(�|�������b��{j�?[��o�3      L   i  x���Kw�H����`5��4�c�4>����ot*`x��~%�$&3s��U]o�*�B�c}��d@q� "�J�cX^�D���S�u`A/��q
%���f��F�� "$ygYȰ��B��nl�*�j�QguX��S;��τ����!�����>si_-Ǯ7^�ŧ爿�C��n�d����ՙA�|V��h'��Y^9>@�a	r��q�ϛ���|O+��i��|��D��5P�9�k�� x)���f&�����p!� �|+ ��t׍ԑ�v�j�����B��]Tt��J'��憎X�p�'�� |�P����{��������w7=�)���ۗ�"6�FT?O�)�)�IA�1$Q��RNf��R�"��W~B�pw:�6)��X���{�`{�<;���;^^I���+W,N;]{�i`&z3��#[��S�W��b�>ߔ�'��Q;�nǑYJԏS:�`�ؗ��������	P��n�Pj�'n�_�Zc�ۆsH�e���),(_�ڼf���x>̤H�V�{,{`Dl���]������F7#�������L��ev���g����9��pY�#���]��6$t������a}P�=ɂ�����P�FUj���և�)@q�8�����iU|���7�kn�-a��z�<,�u�?7����I���m��;+obu���X^��h��%�&�K��R�Y�a�6��)��A�\����?P�>�g��h��eq�S�r��վx|��4,׻���s84�K�ܔ����w[���|1l���Q]�<��΂8J����d�
3�F3�%S��e�g|o�����s,d��S��k�~� u��S��?��N�o4�      M      x������ � �      ;      x��]Y��J�~����7nG���L�S�8���|���I@�d�F���5XJ�Ԯ}�ާ�2qe�Z�2Y�|_¨���cw�t�mk���?G���9��P�o�7�P�3{�vX�%��Ynk��^�����B���"Yw�~N+�A�@����:�c�����o���'ڷ������_��M4=�j�+jv)ҿ����߿ž���t[?��ږ�yx�tcGу�L+ҝ��P,?�<7��^� ���@xY郒��Լ纯�ı�]��T�X�k9ݍ���ވ<�����ܕWNB��G�oq�`�G�k��Ք]�
�V����+kD_��"���Ad�7yc&g�ʃf��S�]�yIġ���U��dJy��rw^��A|1~^����_��G��)�Z��Ꝋ(1K�����I�c<'���=�W�����g�Gf^��ib{�=7��� Ջ����]#2K����L�]/�kW�-��ڻ����O��[w9�쾝O��lg~�~J�j,��oDKY���o�_�`֭��Fr��e}&���Ϛ%����f1ח��Ct,�;�t�������(���)��J��B��#Զ���lq����Q��/����o�[�΢Eۖ�/.��Tl��.�/�q�c�pM�d@R"��]�L�7�����`� ��f�s^I���We�9�Y�$�7ǜ'���jޭK����C�������2y٥ć��"rr�����'�O��+=��7�N���f="���sOU��,:
WƅT�h�b���?���EP��:��z�`}[��g>�����zW����Ҽ���%���Z����1z9:?3����zz��+{=9��x�K.� 7_iG8
���~���^j���w|+o��.x�U�G�5�L������I���� S��~{���ۜ���W�=��{[�L��r7M�����k3_�y�U�3X��W��R�B�s�.��O�WE����e<���E�0�[��S�t�p����v>99����7+˵B3��ֱ\\«��7O���/_qEJ|h�+w�k��W�dC)������_��˙|g�GU"]��ǳ�2��.��ƾ^�/k��^})��,���qִ��Y��*�Ŷ�Z��a��y����^�i;?K�HC?W�sX��y�G������O8�C�z�<A���.�_m&=	[z���1�5�s���;z��?v��\��"^V�[��"��%]�+��]�����wk����_m�$�0��NKz�����7��
��ocѼ�Neͱ��#���Ԁ��d��z��g6J27yi�l��,�}SW��r�����9h��\�V���r�X!?[?_�ͥ�d==d�7��(##S��(�\����=����<�(���-������ꏟ�X΀oAb-���C{h���чj�ÇQ�M*$a��l�� (�����_Ym � ��� ��� �[�ie����3�z����b뜶ho�)��8ݟ��=H|��F�8�[�pz �pz �pz7*^f�	�� N�g��]�<���o_]��x�o.�� ��מ�|��yK��/�E��V���#zo��jx�3���� ����3~� �Ҋ
�<~��~�U����`~� >�R�'vҥY}����T��Z��R���L� ���nz�^�~,/��1��U�u�樏EY5-������l����������3ٹu�`N�`NU���mi�9�ӟ�9��`NKl��)��~�v�?���/\깇�Y���|��~Zll�-�;���Oý� ��P]��N�$��rk �~���0~�]���@�]�tɦ�C���j:��d�n�A���+/�bW?X�k��f�*�ڼ6�mǮ��±�Yst-�5��T�N�Pz��!�ܮ�u��`�x]�׽*����# 1�s��D I���_9X*Jz��o��Bbuy}�<́�;�����(y%���>�O�`��p��3��
��g%�r��>��$/��8U�Iuwv�(�]wJ�3�Uv��ܪ/zVK����`��<��t���?%�\%�UzWp�@����*=��v����g-�	�>XȀ� }}ٷw�-E�Ї�0Tl%@����3��n �>�#��pw~eZ͕�1�|�ק���������ka@���iB��8;���K�pv�lK����t�	8;_䨀�SbWpv g����\��KQp��iz�5ɟ�Q�/����̉*CRu>;��~� �H�%��2y����b���uLj��Ⱦ���cG�V��!�
x3v�����se%'IUF,��n5��+a4��4�f�=Q�R����>D�h>�+ubO5��I<��$���8���]��G�L��<���Q��4t=�M������kX��Z�N�זr'�� K�2���\�Ѹ!n�:�Nz$*8�t�'N�$�D�}�
3��oW��ш֎m��B���s�d0�I�iT����jt�+5�4VM��T�ZͣFO���Avd:~(#"�p�Y|#�}�æ�̡�hjȝe�"oQ��ǜO�2gيc�|ie�{�T�v�{��j�I22z�� QV�N2ukcf��%
4!�fŬ�ܾ���p*�kӋO�ovFg�/�J��v#n�]}d�X�j.�g�~0S��%��&8u�	N^����+�$�F4�L�qt펶�X��C��)���*B�@�~0mu�L1��SC<l;FO�ss�k*��m5��r�~o`A0��k�mv��F�>�*�o4����F�x�g��D'K�u )vR��ޘ�@a�(����i�|��ż�C���W?�&S��I5Ī��+�h6�@=�a4�"a֬%�7?Ф�ߣ�[M��W4�ySY9�Zg��|�F�EܿJK%�����������0�m�:�Z�3;��h8��p�0�;��_����(��@� R
 �"���4[��].���yr#�M�ʺ@ ��u�}'��
BY�����w]i�Q�J������dw4tc"�,��-���`wv�5Nokc�o[+�j��'����?��ޕ�1*���1���
0� �0� �0� ����$x%x%�-�~� ��
�J�ۇx%�y�|B�5{-�f_�5������~��q���J@o��L�m�����~:���/rT@o+���m�����x%Ս��i�p%;��
�����w��`��z���Hv��;��k�~Lp�)ʵF���8�h3�	ue�R�hf����*�ƆZ�x}^�̉�N�Nkm�S��2�Q�"7�=����3�7=�!3euG��i�J��L�c��ڑ7x�*č�#sKKLM���I�;Z������6�ihR�Kә4��v8X��ҥ]�CW�v?��o��Z,V�*1�g'K%��E�8#^,��ih��"C���'�P����I�4���SN��녡�y2���xS��Z�y}ٗ�M��C%�:.Վ��|K��T���� `n��ľS�ąP����L������"m�0ds��tdf:e�u��-W��,U�P#`u���\c$t��j�Օ	E�`Ά���(Aѵu�>`�`���YY��θ�?��Ǥ.
�	��޷���G�K]��\N�yv�c���6�C^&=~�MD��QT�&61T�r
ZEI'r����%���e	�h>L.���2 %k�jԒ�Q̕�	ԕK;q9�x�����g�çH*e��N�NSh�\?1�X�!n�V�I�����C��F����_!�^�Af��I�#��3�����mGO(�Af�uv�����67t}�B6֦WYu�p���KVե��Eaw�X���[�h�n�f[�Uhq��:�=�\� ѫ�����0�r�a3K5�1Cg�(H��SH欘�%V��r��C/*+�á9PXm\��b���΀���Z"̕��f�悞Z����n��j"�����4~Ѯ���]l۲	��D�*8�f�%E��om��b�/�\"�1��NW\t'���kz�I+1׵J�R����B��3@OB��v}�ب#]Ac�rb�ڲE�D�*���7i���d�#*N] m	  �Ċ��}C���^%{����.��d�r��ʪR�G�+�T��*SZ@#VcA���1D���3ҭ;FO�(��M�a=�E?\�Cd�[��xT��-L�S*udBr�a��4�o�:/nZ�3����AoD&n}�I6�]�,��+��7T�ͦ�b�z��V*kP���L�˘i8��5ƽV�Yp���u�XbR�k�j"���<2�x��V{E�wV<^�N:�y�g�\����V��-���@� �@����P6 eP������w�W@��B��B�� ���o�^�]���G�c�:vv,q�R�,��WX�@������X�-��od�q�d��J˃�����wt�z��'gɂ ��y������(hSö�և86F�8�,����m����u��Qj\r����0������^[�l	����d٧���R7?��x����D���0����c�%��K�Z�>Ϯ?%x|�!�l�v�q+jBio�x���4u��}�Q����nD����{;v4=���@[E|~���XNLK�:�i�����T��J���*��&*'�����4%�JkD%�����v��o�oƂZ�T&��81+���ecA��|��n�Fn�4�3=�&����Yn�U�x\/'n�ߣXkk��͈��#�Фܶx��M7�m���Q�Ǻ|
	��Z�m��p�^��S�~��V�sE���6+�A������w�����������m�ҡ7��&��yl+6���}����I3����Y��J3���Љ�.Mh�O��N�q��\-hi貍�7�����	rN��;�ȱ�J�'�,j�Kt��6��t$�[k=f<S����HvH���jVj�?ntSM��?M�.�R��&k�i��xf~p��,P@�7���мk�u���S�Ҕ��f���J:43|jN�I"��t�-� ��?r]J�jCC�E�a��dKw���x9��k�?~h ��W�[;��vC덹��!\���~0F}�ۧ��jU�U�e�w��<�ʮ�X��h���>λ��k�����F��dA�iX�/d����v)�i�I�{}��G�!aְ��f�n�k"3G�;K}�䛥�"<?[��/��j���i¨�^���լ(�r/:��a�ݲ��;jF�RR:�i��Bpl�wa�w=�`zj�r?�Ȼ�t���xQ�W*՛�E1!4��C��-;�!�(h�Ѳ{n���7���0��:r���a����k'�mn/㊁nZx`Ő9g���"{���qՏZ�O6H���i3)���i�:q>P�ςV�6ӟ�ҭ�����z���"gD����XY�I��?Ƴi����F����#�X�Q��{���ݎ�[!�&����h�=�,��y�4�z��S��΢È��]�.�a����fgrͮ�&��$��8d9���f�SHwԁl���x��j������z��0���Si�HuFW��8ZY̓�]o�w���xkK�{�:OW
TM�=�b�b�����cӺ[����ߛ��pʴ4��T���w�8�\Ph����`�����G�����I<l̵��%.Cm9�L�1��Ԉ�J��3���թՅa�O�h�̚���񼅶�zKJ��L;Ԥ�g�6<�'M}ߐ j�&����S{͘�Xќ�Y ��5'�"����1zs�w�_7�1�]����N��L��.�#���|H�a:I�E7I�E���iGhi)#�m�'���|��l�P)�SJA�Hl�^O��zf�A�у���5�;e9�1�@�yOt�S������!�������2�>��^,��F���^\);s��c��n�.��Hr�N� j�u5���~R@J=�S��b�MG�������tv<H���%\�������Q0�&�&�-P���������+$�+�Zrf�G�`�����B` U�Xa2HL[ݐ���X[��kO2�&����A���^���2px�U����e�D����n2�����O?��_�|��׊�\C`�|���>p�2/[�_A�vhΰ㮍m`r�F���ː�}=���{���ê�_�xq�oUb�0�S�(�a(��B}<��4� ��AoΓT�A+[�怠= �Az@���|���� C���ȟ�!�wW9&��:!�Ӄ0��ߌ�.�-/��,rz��9�ޕ�����Nʊa��n�*qv�z�����USj��PPj����U�#��=�5?�B�}@�B����> ��B�:�c��Ч��C��l���b꫾����� �<�?~Ѻ6j����xw����
Ap��ċD�-��)�
��|�XC-����@����~�a넵Z� ��|@����>et�V�I�����o��7|�1�Z����o����.�      N      x������ � �      P      x������ � �      Q      x������ � �      T      x������ � �      U      x������ � �      V   �  x���Ys�L���_�U�u2�͢r��������i�UdMn��kLL%�	C�/���9p8�վ�S�xC��x�{���ΰ���+��k�۩�0�)�.�!C����	 ����jO�@�h2��1�X*h���9S�4� ��Yk!�#�i�|��h������9L)fI��שּׁ���Ӌ;��s�{`U��|�d�4FA���9���}/�w�l�&0��L�6��VO@=7���mR7
�3��9K����#�3�v�ק����OA�5D4r�{�ʽDh��tt��=c�7K+,UC��-�}'�~�ϫ�I՘n�����8��1����?��<��S�Z$�8��!�&�t�ϩ�޹�g�k�$��z���i�0/�N���b�q��WׄSo�>�֯<K�M���q��(�53�AY�'�n��[b�_����k�M�?'i��CM��/F��Թ�<���4`G��Dc��yaB���߅�n��}�K};�����;�!�[����3U���<�k��ި�iM�{�l�׌%�����H\8|�8َ���FX]_�M�h���Z�CA��)U���[��N}̷c�ߔ"_%�c�R)�5�}3V���֘��&�RN}������������`�Z����Ѱ�"e�2<��VPOaH�z��L�U����I�	 }ӝ��ᡧ��N�]YIW#���u���Ii�������|�x�	q��-��wHb���Bn*���~`�IdK���^l���0�Ǽ��lѪ��oH�
�R���BfӦ3T=Ya��:��ߙ�(�/%T�W�R��P��h��t;U�^vF��<ȍ�5�>��� 
������g�78.�Y�ר�2�Ld����i>1�R����7tq�"������?ϕJ��jpE      W   �   x�m��n�0D��W����	�o�)A	�@@�`Bb
��4�DO�;�7������no�ۥ1�h������(�{�&$$h�!SD�Fq�O�v���B�See�h�N���4u�����v�����쉾o��*S�I}�h�� =�1J�/��xB��6�x�"y���Z�*�Ys$c{�ں/3}k����O���|	���2�fjR�؜O�1��Z�      X   w  x����n�`���x1T]j9T���~ҍǊ@D�\}��n��ff3y�o�[���|e���)\8�V^��c�>�?VE���Q+�0b��?́Bg^2ݍG���sF6�fA�3�a��w��������L�Wu��R���y�,(tfr�ȡ��2��.[n:���ꜝ���J�YP�L��|c�g���zp��Й��Z��5����{�͂Bg�����x���[p��Й�]yT��m�Z�YP��@�ާ���$��1�fA�37^%���z����n:3�NU�v�ZOE �YP�LU����Q�k�5/p��Й�kso�}�>{߶g���Μ'�Xѻ�\̵C�n:S�V��\��ofE�YP��ϗ�`�R}	l      Y      x������ � �      Z      x������ � �      [   �   x�u��
�@E�o��0ތ��̮!I#!Apc8��!:&�}DP�hs��eu������c�k!+����q���E�r<�����w���SjmH6��3�v+����b����):H��?yL��;��X�إ�|��'(_0z2��E��\��n�B��SL��+B�*#8�      \      x������ � �      <      x���钢������*8_vt��T7���o8����Ɖ8�@
�(3��{-��N�PeUu�?�Ot�k���ǔ�Z�ę�tvڬ{B�w�eg	j��������q��/����C�T������"�M��lמ��h*,6������m~~�<'�:J��n�����Gs���s�L�Ҁ�?����J�,vcL��޼�k_~�N5m>���j�x�3�=i�X$5)O�$*�F�;#��B;��EkO��v�?'��L��2�Ē��ЊB�y�)�~�������a;㻬���n�5�ub��Ci��C'f��G������%�[��=�j1g#��~����Z Hi{�#���� JC.G��f�ni{J��M��a�A�8�_��ҵw������]�t�3!�LB��s��YXo�(��G7�a���j�\?(zs��Lw��:�o�����}��~���0�<O��b�%z��T-�H���=g}�ݵ����`�d�z��)��*��G���Ȩ|�ޓ�C�&�mV�S�
���Yք���*F�Y)tw�	=�8�q����l���<��b
��eN���	��ѱ�!���Π�h���X�БH@�>�|2�3G�]G�5�����Q)��W�w���џ�W:�O�3���fQ�����@�:k��iڟ׈1���cL�
F JLy�����^�e{R�*Œ9�c�8���P�h�~���*���p������#mO���n�%;��67@�&�~��Ө�X�&�%��%�sXT��_Wԍ����h�h�)]��v�%�7�ͩ�4�-��}�o��j��2��Fa���r�iu����~
���B�v-aH:�������e҃�g�v�n��J������U��o��A<�N����{h�	�Wc�8����8�)�� IԌOٞ$H]7���[ͺ�R�|�u��z7�zeh]����8�C���G��߲ۯ)���2="�o��&&nV(�'���a�Ս��jg�q�C����y�3W��ǟ�w�/B�����1�a�!��?��~}2�o�0���+Ǜ���c��ƶ��	:�����8�ў3��y4�v���eq� >��q���g��Ӑ���b�o�907�,H����bx�l^$���BR�u��� ��_�<�����+�:�m�)ݒK�]�+@�p`��ޞx
]��AwY�W���PL�b�.te����g�L��M��4]��$Y�����j�'���
�.�G��gI�x�]�'M/���Ko�a�"��L�Oz{��\�c4�/�5XX򝢢�b�WÓ��ck�_��M¼�]�P3�|(�Y�o�&w�F�ь���Ͻ��.^��+{�S���'{k���?�c4^k'-�@�׋�NoK{B1`���(}>蹨����Ű^U���^�_�r`6��-mO9�U"����#3G�sԓ�Ci��`q������9�*,`����Mtg�̲3g��j��y��a�#�M&�<g�X��E s�<�/Z{��t=a@�Ά�91� $�_4�ޗ�<�͵���T���!�EQ@�X����OY��ۃ�Z���j�Hqds��)�sV�ڑ#���y6 �F̑���{F{6;�ձ#��=^�T��w�[��d�w�)�%+w�(��᰼���@�nF�?�a�N�DUT�"'��������[��`�� ��nU�����G��E��d�{c1��+?z�c���)hm�r{Φ���}#��KF���
Xv�zƉ�^����c�G�w�^��<kAM���{^�5,�Í=���`GC�M��?�㙋u���p��l/nQ��x������k�9X�qh_���)vh��?������r�=�����GBt|�M���~~���b�T���z��<P�o<��k�1�R.�]]-A�f{���z?�'�O���iO�k p�����Î��7Ίi�Z[�������x�b��)om�3Z�'�)�ƣ��
s-�~����W�Ϭ/���2�^Kl�l���QO����+�����Pb�1�E��TtF�9\B���b�Erl�<��Q?�g���}60F�1H�K�D��&S-�ڄ��iO�5`w�5�{���O�@���[<��b��9U�M�\�tti�6Jo��
�(�Z5?̤�f����å%u�.d�tI���qM-�G�1����n��r�)����E�#mOq0��H��:`?�ѽ�D��s0����d���Iև�5�S`��r��b's�1��ȏ^U�30ί+�/k������(D �0�!
Q���Q�� PL�Ts�$��M)�^w�踢��;��DA哤~��"-�=r�ܜ�XV3T>u�I{��
�;-PM��)�%�S���N=�N��(aZ4���AN>��im�a���Bt��Mgb��P?Q`|60b=���|����28u&f|[0��lC	�n�G+]w&������v{���Q�:��G��=ŨC�2;��!�L�F�ؔ��G�A���~�X����ۦ|7u�J{֠2��ptqŉ�!�DM��bl�]���]��${��R7|
�s���T��y�w��r\��E��s��8�K�r)� |ߍ��EkOۭ!��cy6�3j5N��[�����քӨk���\@�0A���1�䜚�O|>٠�r3���C���42z���L|�����8J����nO���؇RP�b������K��K�^o��t�B��>F�8<���A���`͢>�oK{B����L��%�H4�D|��w�1�#m�:o�t0�9�C������4������\v�!�}ׄ鋆q�'z��e����-�<�(4a�j�\�/V{*-*��.W�^XC�Ɖ�ء�(O���?�bx���$٥w�9���F�S`� ��������� �O� ���A�d潋4��94F'K����`���\�PR��k!�������6�(��8 g˅h�n�<ƹ�"�ث�y�d��sm�P�~�1�k?�n���@�c��#R���S��(FL�.��jԧ�����E���}��SG�6Z�,H�>���1��O:��>���\K��'e���'#>������f/���_��4Ydk�|�OU���fg��kMH ��j{�bQۋ#L'K%�z��o�+ίz{�c��p�s[G CHu��2X��;�~}��S�+��ݫ�0�m<�'�5~�^�����9�շTD�L�bx/���P:�[�=�n�E����d`��j�ۍE�<_,��)$Vn��)�D�o�31"��veK��\�g�H�%F�6%]4��5R�A}A?�S�a~��S5��^Vb]�6���a��rs�*�5�F6:�0tb
���/F4�e'�r��w����=I���޼�xE�k�@�������gc���=�������"�'8~Ċ�1�Ņ���*^��c�̢�;�y7㓦4j����.�&F,���0�#&9s�3u�%�]b��䢮3�;��ף'����1&��|�}��z�}��A�>���,���';o_
u�!�%�8�'�[n���ƋTO��}��#��~va��l�Z�eg��C�~�����J��$]�#�;�>�[s����d����R�R�㗨���ۂ1���xMƕ^�����D���/ߟ��zXLO��z�T���=#ڞ�W�ZM�Y̖���a���Ɋ/��If����S,�x-(�_	#�a;�ܸ-盩��+����mJ�X��EkO+�P�PS{����B�0Da�C��X��c�š�Dy>= ��E�;�i��z�.W���Jstn�V��-^5�md
0XP�:.W�	j)5���L���X8�k������86N�3#d?O�#�f���rwJ$'�� ��=���t�L���y�o��6)�ď�c��%�
7p�?��,u��kF+$m!����L�{Ҟq�5/9̄���B��,74��&���"7��?fb�9�^�"����<8O;3��s?�>��,&*M�2�Ù84 B�5�%�P0���$�Ko���t
|�8:���Ӧ���w��L����
1�X��b    +e�tc{R���{�����]Rq`�:�£���'X�C��e*c�Q��N��,p}7"X��gc��6����>ՙ�f~��~�0汬bN)�~��~�"�m�$}���j�/�/�+sǡ�'	Ǽy��h���8#��^�N�s1:d��+:�g²���<k1��Y'n��97�沓����vQ_�^r7M??P��L�#l��^����8%QW��0��w�1��H�8N��Q]�ag�!7�`����<<z���K5�,
Q��Q��,���(HuH��`�'!��Ix���B�X��A��i�E��nK{�h/��A���֙,!��h�i�$؃�8��t:IΝ[O�q�}���!*`��� 	1i���}51ڿ3���q�wuҗ���GOٞtQ�a�B΋^S1�u��|
�Y�<kܣ?fb��G7�G��򸫶߿�VQ>�XS�
m���t�'�w��9�d`�L>p�����F����`��CF��ئz����_6���z#~���JL������{��|'Q&U*I
О�m�����`���Sd�8�������'��)�O6&^g��1c����y(g�P���fS�.1�R��σ�պ���]!lx��~b^7�4��N���܇Є��̾X��-P�����.�ʃ�v��J����)���6�4\��A�i���鶴'�=�F$\d'��<
�=i��Ux���=�Gœ�/���������>����4w���2�Umϻ�zr^y5��C��]b�z��n���P���Fh��]`��(�39OG�Z# ���F�=Q�v��.ϭFL�@	�9�mA��y	��}����Q��c�z�� #���`��C�E�.����)0�A�����_�3HA=F-��0v� a��:�Fyb�c&K�r0��4����掉�F��Vq>d��`}(6:�$ &ƇҞ%���d��~h���� ވm�[-ݠ� �=��l���M�����۵P����˝��y[��Rb���՞�� ��7��2-�����7��a�'�°�Q
N=����c�OC!R�B�����v;�@�H�SiÒ���:�+{��{Ҟa�u�P�;�V63@�Q?��?���-�oت<���d7�7y�}O3@��aza���ᐿ��k7���c�BފcE��9i�6��B�q�K����Ĕ�Yﴣ�;�!w�qA��ўy�t��U�F���ȷ�tCχ���LW8MFF��/%Ǐ�"3��/�G�)�E����xa	A�K@�<W��=���ϲJ���ܿ��@�=懊Q��B�e|���t*v;�r�7wu��Q6�X�R,nv]0�S�������p�\b�)��Fr�Vn׫>4o�س���̝iq1B�-�㈐�}B�|B�%��s&F�j�0�.�\��>��2��K;��=�=�.m�?a%�Dcdfޖ����}=��#��f�ʛ���i{�*��^'3�!�פÃ x.�G/Z{��SW���aL�ǣ�ݓ��]�͢�lrY4/�x׏�=eH�p��A���Evxx�G��5���ȸ�#y��73���`�q�P�q�-��(�7��d�x��)g�f����8�Cܼ��b�3�w�)�ˋ�^��&Q�cl��d�����@�#��5
ÚG!
�e`̯,L�]��J����A��rӫo���:=n8��?�_��=I������A��gAzO�3wC�݄�����ݼb��c��u���{p�+�9�y���)0��$���p�E�>Yw��ӟ������2��������9��_ʗEB����v��k��9�_q�`J/�r$\����������ݞ�{���U2N�Q�t��nѶ}��G��Y_�;��u��}��E���X��p{�\f��@)����a��D3�r�rd��&����*�a%PܠX(��f.���h�{Ƽ�Yl��l���Ja�Y*���h϶FS�(�|�g����/��Ua�0�i?\IP��^���!��V?���tp=��9w�v����G����n$M���8e}#�4�{Ŀ�E������C�sA�>�~�S��^x\maTY�)+�尳0�ۂ�߮�C���̱7�7��4���{���Q���K��M����};���f��^b;M���UoOܤ�%�W��O��~�,���ۭ&�tYx�҃�b����������5c_���eg�x��w��_�;�����Z��m�}�+z]K�9LY.���7O�h�i��)�N�.�#D{}�����Us�hz��ca����c&�#��yA�V@K����7�5f�#�����v9¤�D��,#��p����G�
�p��|��+����:'��	Nb͋��,��pH>F�V�u'*ݥ�sgQ\o�^.�1���E=ِ;�[�6����{5j�Y���e1�u��H�I����^��ą�9G�����W��|�~�8�+�Gy	c�	��3*� ���EÈcf���;�c(��=:Z 	�9��
F�Ȋ�}n�p�O.
�a��in
��O�aw8�������$���g����e�a����nƞy&5����tRSv�J7������#N|�_�Fy�3*�/�����I���u��Za�$�)0����n|8��A�2w[0Z���B�V��h:Z1J"���K�,:�E�4C��mGL�ۂ�7�?�]^�6��3:b���m(�����Z<�M�#B�V�g�UŨCci2��*�^�$p��)0b����7Y�S�$�i�V����$��ce)�ˁ-�"�n�H1��^6%ǧ(�tO��lOj������>�����as��§�8��5]P	$�)�EG2�=p=��Umϛ������Ve@w$�*�	�og��#c��}��H���y���ڞ�p��p7��䔹(*xJ���T1�C��/	�jO����~��S���8����(,$f�8�yO0���?��VO��SW�oŉqM��4�8㼆	qh,��/������R6��b&��z�����3�j#��%:�6�ӌ7�~#I����cum�u]�0gcoߑ\�zQJ�\/�A��_3ڳ��К������P/�Z�=��g:�1Ѷ/)�N�v�z���ч�1>
ku����5������W ���/�e�g4O�5�CL����T�˧ݨ��f'�τk4�¯f{�g������uӲ�;޼d�j{�z���q��e�q�wn�L�B��:��l�Q���`J��
:+�#}0D�+���|准Q��:�a�q�U�(L-���w�����е�۳���{	��F{fz}���W]��G)i{
-�L�y4S��f�if�fg��d���jA���҄�i�g*�Y<�·�Xf��6W;R��a���(>vJI���e�v�G�1�b��8r�'Zw� ���-m�kN�l<���*n� >gK��A�9y���خy{7̇�1g���ʬ�m�u�nڼ�:H_���)�&G�*������T�������i�i���������}����<���A���� �j�������4NMCu�1��{����Aex�ώV ��ș]�y�p1lVUV�/�y��'�o������F_�tR0�t�b��S`pEY���a6 ��w7ў#��V{L�%�P8��)�s
at
�Gj�uu�7��qS�`�2ZּKy���L3�(`�އ�1�D��	��&#��M�YS7�f����]A�(B�Ӣ�i�i��#�ݟE1����D���a����<%F'r�^���l�48iAd�w��v7�Ӡjn�V;K#�-�	F_�w��=��n�:K3�-�o!L"m8�EQ�3h��miO�yb���[O-׼��ҞE��c���F6�"�oԏ#���zU�G���ۆ��oh< �(� #��������@>'n&� np��U��V{j(�X��+������,]����W�HX��Ӷ���s�"ǽ��%�A�W#Vs=I$=�T��А����
�������t�I5:Ԇ��4ۖ��    ����f>�MA��h������Q�t4�i�0�tPO�1ʥG�_��_H�� �	��%��_�^�.�!/%�cCp	ջujj{ސc=f�UmJ�bF��CiϊɅe�6���-ܼ#�������'�({���O?al��f�m��B��_���4/Jy��sx�2���ft�o��
�޼��7�*���L�}�L	X�'�&˕���iu�;K߸-�	��d�X��o�I���۰�7f�Ϩk�爛��!:BQ�<Ts��Ra��]��\��ZԜ��ߥ�'���'
C�'�K��69Ӌ���%S���D��f	��۷oز�����1��zV6_՗��:�Ŵ��G\���Ű���[�xS�U����h����:�}B�p�EŘ8Q'�4�R"XV�1���S�:���X�����z��Մ��)�s��uo��]��� d�����H�����KzN�J�5����j{�S��BrǬ��i�6�c3�n�Iǈ�W[�rK}�
���b��y[᫊ᡆP�Cծ�R�Խu��|��ݞ|���ĭ ��A���<͚/�=%F�(�6�R�xs_�n�Y�S=FD}�W�rc۰��� �s��C��7�t����m(R�Ag�+��#֓�Cf�g5��Y�A������_�\:�˱3`��� BDhQ�/F�|����_���bE7��	�0Y�q��z�bS8�JQ�$
3&���̝9	����	s��{������E~ �^�]n�=
�?��,߫-c����v8O�A�gu/t�����>6o�C�x���P1F
u<RNnV$c+;��{���1�b6�~.���Ҟp��3��ܥ�1@9z�Uf����֞�k�6bk_P�<|��zU���]i��x�0�U�����Rл��Fe%E��+g͢c5w������ڻ�w��6��D�5�Q���i�/:F_&��t�>��.�N������1��Z��o��b?��ZgU{����8�����g�f"B�����4�wٞ49O�L��ꒌu��Y�7_�P0FeeE-a>�WV7�ǝ�����S�'qQB�M$���Ŭ��� v����e�c�(-:�	���Y��0&�1�-�{R��_�1��,L���cmi�9"�uDa�I�8
)�VrU�3c���=�/3��cc���}ggn����&�t��}ٷ�Y~|�n�n��jO�kM��|�p��p�$E�ԏ��_�1�V��X�]zM��j-�{ջ��Ӯ�}^m�b`����#~sIf_M?�x�R��Jo�O�d�!����y�=�=��b-<=9Vg*�w��Bҧ��W#N�g;u��3�螴g�+�V���nt�ߊ7�!}(�Ysq����&Z�����4/�l���,�T;R�HU�p��`o���Ę-��E�R��}<qɝ���7��N�{�j������4
ߺ}�1�@�;R�WbY$g�r#5��x���y�[�!;Yz	yB}O��0{
�}]��pf����L� ��wٞ�X��<a�#v�{nWe_u�k�B�ύ�� �8���'T{91cxX��6�o� �c�k<`)�[��Q��j�Z����͌�߲ۯ�p�F��1(Z��Ց��}?� ��IoO��E�^��`O�\o���~~��7�7�B�V�Y�
ꓢ��ϯf{�G���$㳬�O���
@Sg2ׇ������1�}�tb[9�ٳ�`���#VQ����m�Y��e���	���yQ����dx9_�|�INh��[�y�Z�\/I��S��*!��<�k'�E��=���e��g�p8[d��O�_���6���:��>�L�o��P0X]V�{��^iI� �葶��Hxe6�|zQ@ԅ������D���Lq_��8cU�ӱn0�ۣ��EŘ�(�]0%��d(�=�����EňtF^�[y��Y�g$K"��,��bԺ��n$�A���ȣ�~�1�w2�@��Щ���W�/\����WhL��	ߑ]p�B@�EC�-��bΐ��F�9��+�_,�Y�`�a��y��ֈ�&	$& ������o��Cɭ9w:B�8��&H����cxu�3a͑8U���E�(�h|�������8��H�2��f&�bďY�ғ�hz��YP�,k����U���e�a�y_�-'�A>*I��jO=�G�.�2�O��>�5�E�_U�����fX+�It욇QoI{Ƒ����k;�F�V��Z�0�]�x$_�����(C�R/�Ԧ� ��$�Pڳȥ���e��-ܞ"����_L�Q�k)�PSy���]GN �qP��`��A9!��l3�����>%���D�9_.7�<e��F��W��z�7	FQ�����_#�gE���j�Q�g-�WN�������KƆtN^��R�M�~H�1���G�m��2�QG�}��������c���\d�	d�/��b�Ѿ紧���׽��MV(H+�o�O����	8?���~*����r�V]�KFg�k�ڗ��+eh;v:;'��u69Ț�Y?%�ר0�Ϛlw����m��3l�B]sW�UG���vﲂy�R��pRd�|��a�j�=)H�T�{vi�����/��P0|��7�^��I�U���@�䇂Q�z��b��:;I,��=��L@� #"�$���}M�#>p����X������}(=��_��u6G�9�����Ҟ�L�&ݺ�.Uo�D>�H�+#�V0���!�0z��y'����gbQ,
T��E���M���c��2ڳ��x�N��\���P���a��f�~�s1��*%�N�X�'	.����g,lK��Id۪Sn��b}�.����E���L���i"h&bC��cD�ζw4E�;�z��[��c�f楇1�0��ϊp���W�U�O�ޚ3�=�=��&�V��lrA�$1>L�|�1ڡ2�
V1Y�&Gj���L���{�>"�~@��7oH�c�ў#3�Hc�D��mv�)0��pp�T�v�B`�}��泅1Ƹ�1�H*X�+Q	;�L�(���0ƙ��z�%*JQ�-wƓ�E�eǨ���Y&�����'�a;#�����s�4���,̭:�Ն3#�[W�)7@�և���ݭ�yQH�#��د)��rЫ�qT=}�ʧ0��=g�_�����J�,�g3�RL�C��DKGn�ݫ��?�c�Ly�b���"T���~;�Z�D�ҋ���X!���v���pF������w���E������~N%�V�'�{#&��ϒ}�0zx����@VF[װ�/E^���SbD�+��js}��ȧ<	���_��T/8�*�N{�0&������=C^��i^N�hǏX�V����}<JM�ݟ����I�H*�Ź�r��������L�~�:�$��*�%I�#�;��5���ʒ��qY��e���?��a�%���،si��W �G�/��_�1j���=��ͳ��O�_����ڐ�z����9��L��]b�TP�F��:$<��P-�)F`�Cr]'�QKp��g7}2�3��t��͡?��8騿'ď��?_U�==e�f|���5�ӎ�|J˯����=����d2����yA�Mp(8��X���Z�u�䙀ώ�����]��wo|��S���;R��u�R�	b��*N�������[�+�1�De1λ��!x�>W��|!1�<���~�>o���47_�+X�ΈZ����={Ɉ�����^u���.1��8���v+8*��kC@r����������t�O��A]3��C��tJ�=�g"j�(���2��a37�=��#��fcD�����B�u�#tT�N(�1�������Ǜ�zs�'&�׈R��Z�v�r5���Ƙ,:*��z�EkO�Wvh5���F{`GOўS��=A�O��� f��H_���Ԟm����,Rk*^"Fh +z���V������`k��&63b	�Q���h��@���)3�s��C�>�[�9�2ى��;�km��XnDh�4��Z�W#r��'�5�����F���P�C�笕A��r6_���������S��0�71<I����~Gu �,���z{�&���    ��i��Q�s lj�]�� .�r�;�l�B� X�E��E�ZQ�� .�M<��@�K�������~}�lj��O�?�<�>^�QJB�hCNr��$Y <�����f�'�KqZ-����|:���$SVE�w>E���N��}(�Ys��ۚ�j!(a�0{
�Y�{��G]����< �,�^U�N�MfË�3�;3�^ �>�퉗�3������Q�����`䇁4�o=ɷ��t5�v'WB{q��r�ʛN�.�s�xIsYUIZ��6���j11���9�x��_���kF�� ��7cJ	9������^��)L?#�ڶvAu��_�;�a�GH���h"p�	퍛3��|
��|m}�{�ח�x����]��f_�X�	U����,sJȑ{k(�V{�`��1���̰ct�=����}�ў9^��񅙗ޥ��`
�H1����],��p4�ը�yQi{Jnr��>�Xk4Rk6�EI3���l�ͼu�����+��q�������*3M��#�>�ڻ'�A4�Sp�`����8�ZY̓��Ǧ�1#��-�Gy�ǅ!��NC ��F_,�v�b�$p���C���	��4Ծ��}U������K��~�����k�zY�h���v{=ԻҞee��aW�?�{i���ߘ��XLu�.NzQ�I��A��w���-�� fƞ�q��΢�G�1"L2O=�:��ƹ��h>Y��gf>�Ԋ�L�_�7��H1b�I��f}T7����d^U�Y8'#��b���ks���!x�h�X[+nY0\x����3`hj	A�n�I��v���?�_O��Nt�d�e�~���]`Qk2p����\sw��9��,}�W곅��Q�Y��r¬s�ɹM�5C����?fb�AN���r���pE1k�@`='�^�qiuM�W.I@=�f��Ϟ\�[�����<��<�N���v�ľ-Q4���i�B��Xn�K������c1���ܫ���Y�g.)n�����ya��5�B���ؾ��N�a9b�Y�A�rv����f�T�@��[�;��(��t�
��y����$ �r�p�'h�r7����˸��&F4�I=iiO�09�(E����a�{��R~97�sf���7qK}(3B�m,k�~T��{����B��cl�8UT5�pk�P��|z�t�(\�dե}�Jj�!�\�{����e�Q��6�;�'P�L��sQ�ɔ
&߯B~rDu���.9���쳅1�����Xrhh.�6��`5Ox~h�in�G����ʮB"��>��K�qn��+���k]��kDp��7�7!Ƈ��Gj$жZ��E�w�:l�"���G���nO^��&
�Y�p�=>6�ߪU�n�����H��ns��v�k������5V�]w%e�وپ���b�v; ��4"��2Zu4�y�#Ũ�8�&��L�D�.Q��`�[`l���qєN��H�S�+GF��9���UT>��@T�_T�~t�k[�=6�N�;�Ali�J{VX��ͩ�'�q/Nz1���d�)M2�l�^��7Ǟ��k�sG� ���곅Q����8�	6�]t�t�$"~hQ�z���r0b�D.�>3>�Cs-'O�7���w�w<f+*��=�K0 (?�X׸�����ކJ��jܝ��|��Q^4Z,�6��x�C�ܠz����Ci���*e�Cv������K��=�=���?�/�Q��z�Ű����?�_��+��Ee������x�"Ώ��)ce��6�(������[��t@�}60<�/Uo^�4�r@�0Z�\�wc�Y�S6I�B�l��7�=X:�߻/��jo>M.2G�.�71�gco��5 ݚ���f�p�fF���_��bb���E���:��կo��3��ߜ����z���D��6�x4+�UQW�tV�:So$?	ď��&F~��9���3�t�M�G��6lj�&������Q���1+cl���Q���)0��.G�q��K+�l-4���T�gʛ�]wd�F�U{�e���~�f���7c�Nc1,Fۓ�*G�!������ECy~	��� ��� ƿv��XQ�8�.� s��tY��{��iv��{���=�:K����ps��ldټ	�)1��댴8
N�p6I/7|� +UܹhIzt�*���#���KS}�%���4�~i���|=�+q̐�n��`��׵}�clO�����w���w���Cm�?w2
Aw,J|ԫo}�O�q���r��(����-"�}
���;X�p�v�kT�W<�"��z�q���{�}��nP[�?����?�_�D�C�����?ob�3D^����}��Ӕ�΀;`k�o�N�x�������Y��-:�QL\~(�Y��R]�+���XE��h����֖�_����&7��w���u^m�s���Tn��cdv�J3.���c��Ԍ�|�����f��]Q���r�NPi]����hh�4�u^> ����4�?���qT W�Φ(
���5��A_,�st�}�c�|r��~20���B���,�i�9�^~��h�d�����]�`����9�G�ia�eF��Ѫ����6���=���󱯓�m��D�<�+0g*�=��!�r?ݮST�t[�����߮M�:�æƸf�=FA��ŷvp��� ������Y�
��7��޺A��W�=me��?����}��h��Z3q�<�G?�=�=?�Ld�u6�95:ty���L�9m ��3ڳ.�s�"�y�:��)F�����:�(ɪ�+:%�O��S����b�����q���e;ZmG�ڹY��a��4U�����4_;�_*!���C�8�V��!k����w��i����S�"ux��HޒT���}@��y�I��g����sC����M_)�UT�g`��s�H�JL�\;۠��c��I�W��Go��ˁ5��ζ�D�Z��d��c�p}:�����bC�!8���$�9cꂨ��sg�>*W�[����L�lJ�50�aC�]��Pڳ���lH��$�LB���`�rcJ�V�{}畝�]Tk�%�<i[���&����="�y�H�S�2#�V�;EV8�.*�L��7��b��F�>���`�JJ�p2��^U�����҃��lX���#mO	�*�LOpj��CG���lO
27V��e��i��Ĺ�~����b�����4ᖝ]����O����]p)h!�`ʯ;�,�-0�O�P=SI�T�Ag��y�χ�1O�;��z^Hۢ�o��u��sT�?��\���V�B����	F�
������ 򧽶����4����'�{����[��1��7���1y�XJ�UOd=?�ag�ɤ����ӏ�f���ɱ�;�7@�Z�CiϢ��\�(���3�w���"��q���͜��k5/��9��d5F���.R�ǧ��~�����Ztw�	���t���}B#�Sb���X�Tv��p6�KDȲ{ҞA�y���_����8���?�!$�͗���������X?*��岂�9�ۺ���Q�6��rT����|A��-����P߳"��e�|��>}����.���ƽ����<��Kr���rRY,���S~p�nt�﷋|20z��y�;��д>�?0�W&��(��/j�*�2�=ۯ��gc;7".�����A�:�(�}�A�Wc�r����/i�D�ķ���w�=+�:_�w�u�9<�u��g�$�baD<��(�H���������b���.F��8E| ��>����q�Y�}�:׻�j?!?	��j��&�0
�X$�y=үOP�z�0�e`�L��MG����$��S`DH~�rq�����5����v�q6�BeǴ����U)u�ͷ��]b�Os���ZI���^����E���7c��Mߘ�H��&V2� ���d����h���f:8�)3����v��/�٩g[%�KpO��/��H����Ѯ�/��J���{Ҟ!T�����0_����
�?dU��pr�o�w�8��ã������=6��yvgܾ����l3+g�ޒ���X~0�!^_#� �  �l���(J�����nZ�;PB�L?���lNr�]��g�ᝲ�Ҟu]I�T��e����Lؾ+s$��z~��j)����z�c�E�ʎ@��cu8�k�?���C�����F��J#R�_�m�b'�����Go-n{*䁓(9�3-�`D�����p�j�0�P{v���b�c��G��Л:l�B�#��葶�l��z_�B0��Qy��E�Ƽ����Da7�P��ۂ�~um#Dp���i/�t��LU;���Ԑ�v�M���ݾ�+,e�8;�����_+��&K�3k&ܬ�<���Zy��8Կ�俩?sh��穤��ߊ*9����}|\�C<���\,&�c3� �7��+��83�ԲԂ�' ��д�Z`����� 7+B      =      x��}I�������+���_��W�$�w�3B��輦b���H���]�AG8���v%UY���X���|bac����7�?�N�,����|����?���):�k�t�&��ߏ_/�j��O�����G�Y���;�ѡ�$L�M�1����~����X��~M��������g�_Sl������=��+�0=��9ْ�7�P�B����%��V���Pt��b�dI��a�M�0���>?�kmt����	O��\
�&=�zl,;���ί.n�.D���*K'F�Uy�@1Q��D��o�RNy��gJb�+��!RL�:Y�Nt&^ZMv=��}�O����UՉu�w�r�_� u����կ9dk,�4�[ϭ�.""Ɓ8���L�(n~,Kz��xx���d���l{�w�"��G*)��P��
�A�݅����b�ey���x��% �pEV�?y�����ަ�󂜺.73����d�0&Z��W�*u'��xeV�^�6�����Z�.;f�h+�V59�y�o�V�Y)&�Lp5��z��������M��{�t{��
�������G����9�;>���rP��������u��f�#j��kw���Vm"�n]V=��	ɆP���k󲒮��9�r�;~�I�Nhh/=�x��E:��a�me�F^d.�V�	߰��.hM_����of��2L��'�v�>K�uoWw��
��
�K'����/�Bhnũ�ʎy&��@�������:���l����"=9�$a2^S��UԒ��cE��F�f�C$65�����0����B%����76�g{#��_�y�ûv�w��7�;�����0����d�Ef2���@TL�h����"����zŸ���ԉ��έђ������S�g�![�H�F��������A���dYxe9Tߐ���`���� "�;��r�f��S��zz��	XE1�$�i���=_��=�+�3����3�	��ɟ=�3����A�@Z�R ߃���G�W-D_� �Z�~���K�N$���eh}��Nw�Ͽ����~p��q�ma���
,�k��{cApc�)��s{{�Ff�r�*ԂAnCkRvz�y�$]�ҶpV�	]	�N���¡!4*��Ċ&�H77.L#(;�:�[���<�-�J���D��T�?l7:~�Ij|Շi�-H�8�����P�+��̾���٨���UQ�<���I�
k��1��$L~���`�{���Vv���;|fIdq�J,�6歫I�%ʮ/H�N�4�˹��p���o�K"ل�ݟ�K�}�xL.���r��t����<��ۋ2V�HnEx���e��oOAձ�Î��w?�e>�=RV�[�^^��Ɍ��18�y �@������y�C'��|����vo/Oyn�{� I5���}_n�_Τ娇�?��0�i��b�ze0��j�zۤU��j�Fo`B�D뀩����Q�d[3a?M4������}��|�"�V�Z���5i����iGn{9�<�ͷW"����ko$/�Eت�|vL��~�aY�ymF�i-o���k�E����ѫ����Ȫ��՘�@�?��mbU_,�k�h���F��{{{�y:i�-�qel�P��k��h���!�h Q�kUL/0�6��
�X��D}��2/{؍��H���VbԬ%r�[���B�������r��`�(��Z]��l:���sǎ�]�5]�|��G'����-��%;��^}��KP�^�g�r`�2�����"Y����?\�O���ɹ��n~lN��_[^cv.�M����;��n�އ1�^��Yz`����vd�����
�<��o�A���b��PIݡ�eǪd�U���9����*���|%�����d7&|XPj�M" jҩ_�*?|bߞ���E �����7t�9�@�QP&���W��}�lu�\c�0/�����ݼ�{�������Dπۭ�}bxN�M��g��}C�T��
G�E�؍v��a����)�HXLճ��$΄�)����8��an����$4�;��� 7�����pmɊZ�r/"�ݡ�����6	�XZ��#cU4�P@3^�P���J'Z�X@U�6ἴ�M�Uƙ�lڄ;�������y&����:B)91�n�<2+��gT�ɪj�W/��};Hd�4ׅ��d<���`EO� ��"�4&�����u�G?��S�Q��*���\-aBEf�|�jv�ջ!I�r�����^~��?R�(Ϻ�������߂r$6'r�p���y0K�������ʹ��ⓐ�I��OF���_�s#qG���rĝ�Ղ������X�!�Y�T�y&d��4�ИE4��>p�������ۚ^���0P�+����݂��c|��ݥ���Kp~��M�#{�
������ϊ��⸳�C�m������.��à��K��O����]]�H��B��[�/0�����d *�xɻی�Iq��>�4y���
F��G�&��+8���0�"���'�$�JΤ|W�9u�i֩7�%�4���2Ӡ��[f�a�س�j?K��/|-?��W��<����Nئ/�L��ً���EƜ7�s'++����|�<�M�ke	��4kK��:w��U���.{��$/�F����$#����D%�6���^�5����R㪎���ZL��tL-�'J6��4�V�k�,M������Ie���6X,B�E`\v��1��g�~ ��t~dY�t���j��H②2F��s)�i��E�A�'t������*��Z�8��q ��]�� RI�;��r�Kpvb�������������w4L�ma��yq�aけL�fSKٜ�\3*�����q��ͮ�勝LpJk`��n_���O�k�K>�YЖW���|	g���D�pR�-꯲u��^�[!;g'8�v��޹0���qlrz]�R��N?j���<S�C�~PmP�F�hM�{����F�N�w�|�D�!2+����2*�.���׺�A���3��s�g0"_�2KB&�#*�7E�������j��A�{i��\�d��G�!��Vq���ʯ�Z��-���:I0)�7��ʔԂ��\P����nM��-f)��}U�/@0�����aIk,��� )�C��{=x09�UC=�L�'�V�F�J���>�9�Lm=�|�y�����g����r���ef/6�V?�.��-A;��3m�Ǟ����VG��>ټ���HR�UV�"����4<�(2*��W��F)�B��AFN�bM�5p�,�}B�B�y�@�9 oC�<�d�q�0��
����X��6	U��{�Ѱ�и��0��`��~@���g�s��#���K��Ny����R0:��g�艳�m�t?�nj�mE���A:[��Z�� 8��J���e�ǁV`|��N���	�We�(�>�*p1�G�};�؜�*�jv�W(��l8}��s�-�g�,B��r��Z��&L�lT6�g4���ɔUDɁa^�[�㈔���K}^�_��L4$�+�	r�d��dd�(W��OE'�i������¸�n�%}�R�Wp�-�C�׬���;N��1���*9G6�X��8ee`��ܛ��Q��B���q��~�Ĵ�e���"}���G�L�>����>[;��;ê�����5�j��K�7�b��8�x�>����b*��I<z%�L�}��ˎ�(88<E�yn�����2�G���;Z���pk��p���@��Rw 0_���r�.\`�c�8lZݍ	����{�Z���ϖ�:,���N�h�t�q�-�_���<e�{N�3�0�"��y��1�0����� ڨ��y/���%�s��*�Ai�53����-�����E;�k��]��h��`����?F:�ޜ���r��`�_eEչ��Tߣ��s.>�|+�%F�U>HƖtb�����jy��B ��8�g�E�*���%�$38�U*��9#c$�\�8������lY_S8,8ZqX�3�8s/�`��(٩ضU����kW
I���WYƷ��*�    ��{{��m��Dg��&hop��
%Ɗv7���0�5���1ҹ�rl|\�(<`��j�[�v���������� �P��2�{W`B��_ۊ�j�;�7L)�I�a�V��?y��?U���i[���bz�,���( Hj��o7�x���i��o)y��b����c�Aˁ$�lzl���W�����ř���Y�4\X��?�O]u��`a����ߗ����g6N�qT�d�������F ��U�S�Kq�Ћ�7�6�
Ս��o̈��p�:^|jb#���a�9���Ta<�?�f�{]�V;�h8��]��<���v��c���0�hz���ׅ#2�]<E��9�fW皗��+c���,D�GE]1��YŠ�6�k�³+��O��������g�:�/i�l�2��ץkb8�����׷��x������Zz�W�%�΢��'J��y]t�	�;x����Go���{�y�L�xk�}�:ۏv����7�'�c2������c��lk'L�j�v�~l�3V��Y��U6Eـ;)4�&`��[3�� g0�6D88��}�9|"��1J7���Zqs~w^���G���U����h	V"l�=0@��ڼa� �I�[�l=L�p�z�#�o$��<βe�9r��B3?�/&���v�w~��;}�W�}��Dq��[_G+t�9/����%�h�ش��R7=��u����j��\�%�,��|8Y��Ng7�Bdq�sc����ؐqu��i�;�}��P�}��u��������N���h�WI^�� �cq�����(p�pʾ]���Rv��P������z\�����q�����/�Z�r�[�Q���e���y��j����?iw��ߟz6�w������a��!h]��9�7��Xcp�ﱾ��V̌ݝ�c4����p �,���l���Y��2)���Eh�z�Y�(1J��G)u\��V�x�ܢp��j>_4����5�3�U��_����{2�"�B"0�\2�}�)k1�t�Ȱ�>�(�I�� ��a�|��E�������#1����Â7;NOJ�JZ	��o����3�k��b` �8v��LU7�����Q~���̙�c'�N|�g��Q����}y��>e>w�Y;A6�2m�99�?��`�T���(�,C����W��:�M/J �@(c������B�.oK��4�M�>�<H��bM,��ri6���SV�8��ҝÍ�&�T/B�������R��{7�����ҝ<�+�2�}�,�ܐn>R����7�@ec&Ǭ":�����~b�I�)1�M!*����"���Ot���N� jǶ����i	��
8��Y�*L�
�>�4�����X��GGK4�s8\(o����ak�8�ȁ���8|���2g5�(�}m?����G���֚�>�!|�^DØ�����Ι��ț��/o�Յx���o���S�x����(�����s*�����>ЯfMtN�B�2fdm����{'�@�8̈́�l��G���̬,B�V�� ��E�J�o�#\\�y������@��H�� ,����7���5��R[a�%�7p���U����h!M^��Lև���e�Wv:X�P֨Ecj�:1��	.�`�Ξ���T���IV��/���g�ӄ��^�>jz�&�T ۟7�q\��N��giH+}��nE��������Lo<���Lo��Ί�{
Χ�M���q��D�PS�4�=_�;��Ip��,��)��w��ס
i�]��ht��}ћo���jn��K8Q$F#��}��c80��(/8�}1�%����X|ն�ر�:$m�:�#u�ȳ�Æ52~cٙo�����?0�#oO���,j���v=P��8��!�r�S� ��J�ua��S�؅�ҏ��\�i.�YEwC���s��Ϛ�NEB�_�`�:�g���I}�R���o�V.%X{�>N��+Y���˱/�!������+#�S�:C�+\�D��]�_�w��	UU}q��'+��Sj����D�Ig��0�	s�fwѨ�xè��E��qC(�h���d́gl|�w�|�ۋ�v�3`�a��'���f��ۢ�(%y�
���EWT��v�둡5�'�^���D>�i�6���r�Zs�d��ljMr�:H����T�W���h詸&
�]���~���A�G�O�s
~(a���_�Gr�/E��d3�3��Ӑ�^xQ�3��_mO4�y��.������"|�]y{�:���fWcs���(X�F6��K��Db�*����N������G
�(�a�ڪ�{�|~Aſ0�xc�OwU�/��k�c�v��/���I�5�l�݁T�
�B�x����b{&��E��"��"��؝g�+^��!�~P\_���֫:��������m��/�:T��:���Y(D�6�(�)�E,гt�+/��;*�>����qå�%&�7R��-84h'l��尯�ڼ����i^N�F����(�<��\�:�i{Y[��6Xm���\�$)��\.�)�c���A�q�0��tK�7D�L�nI�}�? hX��"�(���/&�a|L�{�n�uc[,aI�Y�a/��"��Y��K ^��M�b��Qe�~I��W��q�����V�JA2~BQ����ا�p��p���A5���L��d��es��K*�a[M5a�Ց9�����Q2/<�8�_L�~���sX���ܼ�zY�^����AUtx����
�Q�?�V��w<界~�(eK&�ky]�%��m>�T�����]f�M��/�p:��n�����:ww���0�|�X�y�Wx� 	������~r�k�pcZ����ڑ|"�|7e@����BW@�9�¢�ɾ�C&_�5�|��~�bo�������iB>��ܓ:��Yz��4�"u:'����$U�ҶC1���h��$�"����Y7�Ypk$_�d��,[o�8jn����k£��[���8�F�¢^����Z�&�ʏ�}���wK�e�/^T��?|	{��D]�{���L�a�h��M�A1&�l�3}��������K�X�Ȧa���+ �5������9��$=��{��A�e���B�Q��m�E�ܩ@{c�V��#��1�}y�9�ܑ�٢���vbo3��������e��;��ZIp�{gL:��dܝ�S��~��[�6�f������4�9��������	5Q�vJb|�X�Ac���� *������H�Tu����~�t��X�H~y[j�cC�g�!��t��]^<6����M��Y�}+�N��$�$�b�O�60������^Dv\K�c'��[������#��'}(	�Wu�kuc�#u�@�y6���5@V��b0�v����1L�-3Ģ8�;	N!|<�0N9▼?o��2�b_�B�����V�7��uE��Iz����K�y�TJ�Og�rJ�YqA�*x��&P�CAQ��7�z�f����}i�1H/ET�Y�o�Wa͂��[%j��j�'C�������z��gQ�0_�$]� mo�/��j�M��\#��<k�^����O�f@�J���X_
�0�y��3aⶀص��?�]�ϸQ��k}D|��zd�3m��U������nTs"#ܙ��>"��s%+?�ӬA�oz�:�� ��g��6�Y�j��}�B��wX5�%�g44���{ /����Sd��C�ڗ�p��q���C,�0�g#�8����l;�u{�a0���EA��?w�E�CP����b��d�;i���^�~%:ݢ��έr��BQf�~��G'��ހ������K$�eFS��:�({䖞M;�aF��N_����m���^o)�N'�b�����ށ�7�C�����-�������\Q:-�u�-qV�����q��7�{J�e���d�>X��jٖ�"��7��50��&��U�l����┟X҂i|�9�n;�adq=�Q��p�ǈ㬵&���̷W�4���Y��m�mXh�(��<���(ֺ�N�3Q�
����    ޿O>��.�5
S���[G#�fOg�qa�7��=�n���#02!�9�ۼZ"� �֯�� iB֊0}඾�n�p('q�;*g�u�h2^ڟ���{~��c�Eu��&��
�qT�蚝����`6XÊ�MK��� Ko[�6���	�����f�e����Y�� z!�����y� �je`��\�}����Q5���A&���"�f.B�.�9�H�abЎ|-]p��t�c�n"�T��,�/�Yަ����D�z���B$�k�B�C�٫)V\��[�Gs����u�8���p��#��y�%��J�o�BI����q쵓q�ū@��ͦfyW� ���4��ͪ�p�{�t�� *?kqF�初e�����V`j�Û�� �u�sh|��b1��:n�<�]ݡ�R�Β��k��m����tu����ڔ>;��1/p�d.לwZX2�xˤ�[@aP��%h�/[�6{n���nϔ�?����n�>��|?�G��ؒ��*0�Il��5���Pw��!�� Mh�����-	_��O�U��gy��G����.2�iJ���?;i�q�[���a�ѩ���tL�5I��Ɯ�a�E��G^d���^.�558p��6�����H���(/���`�����⿔���d v0hn&K�(���U`��ȉQ$�Y].�ݶh�CkÁ�sv?jE�zp�=�ެh7u��x�����u(Z�Gg���?�dh�%��z�KL�ѝ73/�ʼ�/`�헄Ԉ̺����P0��F��O襎7\�.�p&Z�"�����	��EP|�@�|*�.�=a���z� ��j���TO��FN�Y|�ٳ�C'�u���b]s��	Z��?���$�w}�����EZ�����%Nk%��
��>#^�� �'w�3[Q��*o����ʣ~)}α�L�;wH�#���+悒�F�}��$3Xox�4#��"����.���)8��9cb�Ƈ�R�GX��0�������%mڮ���7�e�m��A��[�8��Y��u�ַ0=���^[�2F�Ϛ���������㍈��N|�w�����$pdI�^Q��7N\'0�{>ŌK|-^@�
�.(��7����>�3D�a,,F�tnݳ����E٣j��Q�����<�������*�4X�ü�pK^d#�)݀�&�S�����e�>l��b�s*����N�G���e/��*%�\1+��ݰ���/�:���f�Q}�O��E��-q�u36b�*�ߦJ�V��� �G������ʕ�F�k�Y ��}?:����ѧL�Jz��.�t���:k���Յ^�b�_�����A�-���&L�!E�KzG�X��K����ѿ������$���;6>��{Jz��y��C?�<��w�X��٪�R;��E�<�b��qԺ��۵�X ֌?��u��A��V�u��t8{֧~�$����zű7��NsJ�7�y��zG�(��,�GU?CP3���8T�0�3 >3QÊ5M�$���]Q\#����.�f�Nu��QA������U���d���\�|�L���ݻq�^G��姭ml�=|�>�����ِ)��6�EDY����ggio��1�0�@�o5U���Δ=_���Kv�X�y5�0�-��\�2����K\3�i��`Կ�ۑF.+0�i��;�NW�	<�g2�La���&V��]��X:��,�]\Eæ�P�Ҏ6۩�l��Ǆ�/o��cr�g�n��Z���M����o��b(]X�ٴm�7uy4G��P�K���Z|���*F�}�R����sK�gn�Y�t��|�Z���y���YE�p��rܑ4�����ۙ
�g�f�3F>*ee�[�	S����WzVzux�H�fz$"-7X�ۿ�-��+��
&�t�qY˓Jr�1#w�hmwg�6�a�}�A�ugV#��T�'E�i��J
81b̪�_P	�G��}���S�G��S�vC����ϱ�FNX Q�_�%��OG��e���^�����y������0�	�r�u�Л5�[U�]�s ۍ�k����O8�W^?���%*�>�z�����U�\z��nko�����=t�h<z��U)����X]�s���@�Ɋ�r�.2���u����*��1��<x�9)��{媶�^ze`w\	�cՅ^P�Ω�{���_f�A+?���a9d[�#J6��N<��1��"4I܍kiܱʦ|Jk��ɣ��*��Uԛ<Z�)X�28���s5aϩ{o�m"V{ᦠϚ��F�T�Y�t�1���~ҏ;����Կ7�$��ܞU^��0ҁC}���J���!.�˖o7��Ð�a:���	�"�V(�R�),���⇁�`����^U<A�b�|�(6�����9��{8 �.���-����fc5=�PZ<����Z5�]0��6��?p�ةw�7�zy�A����ȳ�5�_�vM�J,e��������&䭱��t��\Ϧph��3�C�UFF�ޭ�9ذ��EɅ=�����0O��"�V/���D}�Z���B�A��DЊ��3�Y<�?���]M<Ӏ�ş�����w^L>_W��P�~.gS��~���$�oX��]��������DrK�a�Ŗ�
pU변rx�k���rHiiD�#�S���R�a�zuJ. ����`�������4(BS5��$'j.�
�,�^ӝ�G����[��)Y�Ka0�/w�?+�����?N�~+Z�Jհ�����l��:o��]��E��96f�Na��������Zر�>%�;q��6R�ⱨ��eT���R����T	ɸX��z[�E���[;pWGR��|-�pp|Y;�'
;�3uv��:f�4z��ۜ�Yx�e��K܀	f�ޖ~V$��r��������:��-_Q+�z���`xڸTT����vq~{�k@BZ��X��hA|�cF���y��y�:B�v�6>W��� +��:S�;�
K5���mx���6�+���@C��w�6-jɞog_Y�y�*�u��]Ǔ�r�k� 8);��>���D5^#Rn�WE�J��

�v���}Z��
=�Z	�]ÈM��J:]������a���xG)n��� U�oޏJ\-���~7.�n5��q��ZV >Oz�oP�h֗�)lS��M���\��G�%GK�Q��	��}�A�l���;���,��TW�V�e��,o�"~������K�Ђj����ߨa�܄��8\'�O$t����|	�봮��U|�4{}��"�=B�e!8�;R\^�%fq��*P�6?h�t��������v��O�NN?��w�ē+�!��NFp���G�d?���)3��9�,+/�gӁ�?��;h�g�����lC0���q[6*4*:��4�`#����1����4g#�>'3�V��;�������0�E)}q�+��nj��q�>��ݙ����\O�l��t���9{Mf��[�}s)�l�/䍭zXy�A��,w��MA:�;�J8y)5V$

a��}�.��R%̏I6E��J:*��s��w���F�%��$�U�Td����q	t�:fp�f�`.���B�����T�q��W��Bf����ʛ��l��pNfr��3s,��ow*B��;|{��G����h�U�iXt�b��g�V}�����a߰�ш�;�2/
9�2	��K����\	�eț�\8.̖���eh�G�]��������i�x��:�hD��:���Ԁ+R�L�0u�J�%�=�ܢl~8Kpqv?�l��}��%es�o�;+Y��u36^���5Z�[c{��/0dG��C��e���6�]�-R@z�
y���Q�5W��9���E�
$`$
��
�b���=}Uq�5��S��K^5��@[ϋe}[ʙœ|����)��S4g�:48v�w�v����ǅt2�Hʧg7U,�0����{�m��6͔�ֶ�E��p.��/-G�|��Bl?�U�͌�7����{{t�]��s7;X;a4r�Y��zn*gb�
��R��Ck �	  В�t��]��2�ӎ�M�)$�Vvg8��=���Cz�w�rS��aN{�S�AQd���~Un裆���?T�-��y)��J��ܐ^i��E�$ϲ���9���p��N�񄯎p��R����8�`�lQ4��=�p!'_$#�[o�6�J�H
g�/�G��C]�9n٢<������r�ë�a���%_���V��z7�KL}����n��w���<Eʋ�r���q����q���V/��p^9�:�584,~Y c�d�C����:�/���cH�T����o"�h�a>t���8���JrFq��O���v�0WwN�szC�7��q�v�:�>HT������o*�������>����_��*1[�S��	V,��}u��tٛc�P~���"�o^�E���g�,O�F��,�k4���޳L�Vk��7��b��a;������.WZ��-w���
Ξ+u�߱�m�C/��y�dqk�����l�(�x{���ȑd*�Jl�p:����0�\��;^�V���p	�s��3��ޔ���N����lw����ݺ�� �� Z2;jTz/fx�#�4�6Mhuc�/<���$������eX�t�Ud8o/�	ݾ�a�]�����Hؾ�B�a��25|U��U2�g�}��i�(�5����`��,���r1G3$wv����F>� y8|J���g�m˓���X@1�p�F+긗W3�"^������)�bX�Y��r*�tV6�;�s�ԑ�V�G_�%�3ڍ�(��q7�$ޛՋ��/o{/�<�
�UM#�H�l`��P��
85H�|��ߏ/F�f����;�����S���e*X����ɠG�^�OnB�(R꼁}�-9oӐ,b����,�_L{k��f�s�����}1����p�Q��<]��d�����u����T1���\t�h�}�a��x\�e����ZT]���n��88u@gn;�n�E@D�&	����=D��s��^;\���9�K�3�WN8��������U3�FXJqY�N%��4�)ߪQ�4�e�>a������$#���=@�u	�ǫ��@�Y��-��jD7*��~y^-��"	����¹�@OM�^'*�㽁a&k���s�)�q�s�d�WI�&�wߟ�}�_���E�a�����}��G$_�j��[x��a���a�����nІ����E?|T�IS�w��#w�֋^�0����;SE�Y�w�ly{�F�c�n���N��ʹ�9o^L����V�L�_/�OU��À�96�J������4�.�F��x��K@n����6�J[
b�\fp0c�v�Z�R�َc��)/[RHt��$ؠX N���"��2�Pf�Cp�C���~�}�L1o�\��E��[�{�^R&��H�`�XJ�������$û�A1��d�\
�Y+���OJf%V�Д.���N_S���:
�V����|���ѿ��?~���t?C�O�c��[�,v�js����c*l����g}[/L��!p�����<���_a���'}|̊����.���I���ɒ������V9���vG��Lu��?~~&JL��ƿ�YOCP���㶇�!���"����� ��~�7�Ǭ�d�g|Q}Sإ�(�i���Ƥ���ْ86������a�5Q)�ے�|~�V��_�Cǋǟ)���B��eQݟ�<%Q�}#F��a/����-b��ž�,�*�e�zE�n�oB����?�_�L���'W��J=Y�;�@���#��8ċ�Ʀ�r��v��۷�yGf�lVj�u���,L�;h
2ۿ��)�ܤ;��g�A��%���Df�������w�:vFS\�m�J	���@�C�PJ�Bf��{����(����[��ϔ� ���N�W��a�-�������V���z�r��(���t�C���L���RV���f�N4����O	�����\K�'߭���_�M������/�2��x�mA2�V�}#�!��W^��Z'�(]Yo��k�ª�S^�[��Sd:E��7����z	z���A���>���1[��"�����ܝ��v*E0��J�o��c��7�ϕ�%:���gp+����{:A~c'|'��.0O��'�Q�/�Oza0�NL>�'���u����I���:����/��͊^��*5���V�X���X�,ߞ*��y��u�V���~����}��>�#Ӈ�^��u��q0��(Vlv��!nݿ�!�*�x�⤺H���4sλ�8��}��̓>K����TCgY�Rzm!Q��7�]RtJxi(~�"�������末B8����J)��#�g�\|���Ƥ7?5qw��w�\�X@��P�z���I}���w�������:`5���~Vyvd���r��u�rV�d2����}<0�*:C�?>�%6���e�Tf���R��.��t6�s^?β�{��x�����
n�>��^'���b��������֧���Y4ŏg�[�}�S�U�t���NE;�k2�l������������D      ]   �   x����0	����0��p��ML���KU0�4�4b45�3 N3mhdad���Y�xzfx���p��X�Z(�[�X����Z�s��$s�z���FU���eF�p����E@���4.{��M���֘p��qr��qqq �*2�      >   [  x�u�˒�J���O��	(A��(���k̦�[���ix�S:��:��ŗfV���m.�k��zE�l�b 5��P����)3Gص�B ��K����8�
<�m���en�NjFQ�6��*F��ݰ��Y������#�D�'�L��v$���D���%|KS�PV���[�M�p�%�B!,����*�f�%Ȣ�z�GZ�]��!�W`��SG\�����l���+GCr
��^��T`&O�<J��BV�?���^����Q��E�ƾU�3]d&_������d'$�Ԁp����`���JU"�e��/W⧼��.��<m�ͤ���A�E�#��a��K#|K�|�y��ۣq�-F#��@��+@Z�}�j2&�d���Gő�3��_�$�f�N�0n�+�>����9�Bޏ�N�3�f���V�~-�������3Wb��y�_��s�{�/E1�I�ʹYZvaJ�<$��[Qvg�&���6/1���tF�U��m�ƂFKڤ��$��G=�Iփ���ּ�bM���3�Pf�����~�;��2�u�$���!��A�+'�v�$3����T�
w}:�>�V���ѧ��HNg����W�{<����Շ{9O��Cr+��^��t@mTUx؇��b"(H�3АY��]P�~��Z���qO�4�����P�S\g��k�����e:)\X��}���m-���ӵ풢�<�h���{TO��%(����t�YMae�^}?���u�-Ej\�QMn ����~$-��_�
L�� ;*���&���\skj;)z;m�w՛�P;9$4�~���X[C��ц�%C�=�p���&�A�[�na�y[!�{	�{��'��#Z�m�T��#y�8���Q�G����9����7�4{�������ks��t�AS��(��=~���Z^�����a�`w���y�չ@L�/��� ��O�֒�C餒���˩��w>�|N6��Z�ﹺ<�ZߓkꖻF+���ʔg��Y#�ч��ooU�h�ﴠ�o����v�)����V�ο��t�2/ގud�6���Cա�,�5�Q�%���_�m�W���/?0�=bZ�������X��      ?      x���ǲ�Ȓ6��y���c67/	�� �!H�h�B<��<Yu���g����U�Y}Fxx��B9E!�X�Ie-�A�3�b��(
���*���������W�T`����E���R�� �C�ܑ��_��?������P�?v;������_���e�N��a�)Mݽ�^u`y�#뿨��¯k:e�������=�s�|����~�f�i�8�D�JQ4��D�]:؆�ua��!�`�!��s&N�����´�a�դm8�Vf>F4r�`�-ԻK�l�'��/:*�<�k�:Nյ�o�����i��ɲ8v®�{p�3e�\$�t�8�eܗK�d�s\*�1]tL焧���9O���ךSC�u0؍������]���.�����8����K/���0$f������\I�v������Z����-�8]Hp�c����37.�%�oo�ګ`�����I,��:�z^�T�U�s�&2(�N��Ħ� U�B��NxS[�_�9U^�Ť^�Pgst�K}(���,�Q���Nnq!ݵ�	P��A}���pc��&���| ��/#�©�<H<V=!q_8b�질���g>�&���F����-EsT���/�TLp��Wwu���A�QH��p��\n����|�����S�ex5��`ײ6��m1���O���`�}���I���,h���=5�_�=�RO�@�v?1(-Xm�1(�Wa1vt~X
�zie��v��4�Myp�,��>w�g�I���Ė��Ȫ^ZMPLr�."b�dw���ٹuз��(^�A�u���H�R8��p���	������ؿo�>�a�����)���v�O�F����\���|�����K����_� 3()e��|�'�vG�,uP�����X�z~zG��^W��L��8�D �]2[���f�^�P/�>��C�� }Y1���C��V� fL``kO�ҳ�'\-�����T�����Z4{���D��b�+�T~�֛��l��6ݕg�Љ�7�O�F��P�&{T���3�3s�������}F��z+�}&���(,2\j��/m��=���GN�l�G��Y(��$��*]�s%���Y�T�Tu�p������(��ˎy��_��VfPޖ����pb9����m1�F[��.�^~m�%v>��L��A<n��y�*A���iK�1�l|����o�����V��}(��4g@�͸��e�P>E#p���v�^w��6��C�]��颃*w/=�S���^5�_T	�������ϭ-��=�ey��\!�i�^����+��>���]C]^��y|H2�5�s�����l�
N�b���/�&sϷ�eWe=���V]7і��"�6���a�ݏ׀ۍ@�e��=X[&*�l���%[ؽ@���]�X-].��3*h�/�������R�;�a<�u�=w�!�s��{�I&��e�Կ���[~O<]Y�S�7� �S��(ffI���i}�!m���M(��~�����	:<�����{\����p�����&j�S|r́��t��پߐ�C0�e��d/����8���I�-~�7�� �|�%Ԓ���׃��*}���0�rBW�)۴.o*c��i����E�n
�|����YVM�H}@��-��E#�m�Y^l���9�<�zt�N{�:��[[l�V��܊猎 ;li\O��VU�z�))Lg:�o�M���*?�_�����������Ѭ��~q���i��p��n@�R}����楍�p9&�������i#;�;ܗ�e�؞ݺ���6�_L��a:�PF>�3aѽ��8kR݁�ф:�nl~x;�3����0���3��49�Kb��w{i��uȷ���>��udFkV�5��|v3��3X��s1%1�?��F�i�/�/�����ӪS����Ԃ���]�����uo��G<c(��߸�v��'�:�4�x��M��]�{@�z�56JS���.������i�2��^�#+0��>��5�]���x������'�����o�j��[C�9�Y���X��\vL�%K{�{�~L��N,vZǈ��L�	�� �o^�j�̥%s'��J���^���Q2�(+�/��A�_�#�S�;vg�)9�	0]Wܭ���f[���:���H���+j͈sq�-��(IU�!6������qR�gǜM{a����][֔b�����l��p��P=���4^�=#"�����tg&�Y�Eg��A��A�/D|��~�y���7?���?]48�G�"��"u-��"��){����8ž�f���bE\�߁�ǭ�G{ �|�9m����s�7�P��H����?��o+�x]�T��V[� ��aoG���X#@����it<H����&�z��[�)⩛R���SU��D�&����[�n����D��]>���[��,rKf��-�@m���/@�VG�=�e� ���0�=_�����Ğ��D��^vv>�>�K82d�-�h�W+�������(��Q�Rѵ;L�*P��ӭ��	��V]�Ox��W4�\c��*��{�:{������2 ��(Be�nd['�K��5��
������b�ظ��]��Jt䙻����r�d���L�=G�M譭�	ŧ�����x}����s�zj�T�G�0i�?�9-�Y[���B��a�B\�{�"g��mh�����ˡS�a|F��7�f�dH����i��3��C[���_��<����qD����������$�vs$�ƴq����_db�_���M���IB�)�b��᧠���pǪM��L��� ���t�՜��+W6�[K�x�"��V���&�S�*�+4���=��L�
�p�z�hE4���,nx?:D��|W�:\^�R�n�&���O�O��m�����QW1��\e�'F{#��T���_ھC�c��0�̓�Y2�U G���N�����gXO{A
���IzI��]�z��%l��e ���r�cPO����~O=����p<������n��×�2l��%������;�eY=�����C
��ǌ��(�<^�m��~cP�W�ʗ�]��W��ӺEO7�K{��=��M�n�"]��?%=]��p���2�2^��i���l��tzD�WWC��wM�1 F���ZZ�ƾ���awU/�����A^��|8��$�ʠNl��5��
ϫ-�F#���l��
��� H�L�ux��Ũ���'l�[#��`XC��Υ-6y�\>�_lk�>ʾ�
8]	��{p����j�mь�f.�JMX�3z�������g!����"���85Ǡm	Ә^���¿���� e����Õ8Ű�@��<5��FQ���Amn�lN	����������p|w��荑�!�폜�#��{����o��G�ȷ��3p�Gry���]�y��l.P,�j�퓇���| KR,L����m�o�o̺?{K;x�1^b�k�����ڈt��\Qs�sy`�����V�K��xFܣ���ι�������ΐg���ɡ���9����Y�6�𘜉�V:���s% ��5SsK���`���xa���,k���8/����PG
�xs�}��By��[�C�s�3s?u��G�������jw���\唕 bd���N���>�\[FJ���:�w	�l:�2�f����;����0���=��,�Y�֍S�����ܩM���s{!_%],�ߕ}��gj��F����v[�
�μ*�����ʢ��)��H�OxZS���Y�t�=��ړ���Ȟ����?�/Ͻ�_� ����3>m&l�ަ����z/��Qوt�{�B����в�v���2�{46*�c�����
޹0�-7d��P��«ʙ�����E�>�p��S�"����]U�;t
�P\��v�C��S������K�F����T�<Q���`UŅ���$!�wΙ�6ke�cF'�]�XU��d�o�T��c�Q���z����F	��&����(�VH��    � v����f�1s�S ��g�d�ى��5�>����o��E�NӴ#�����,����*<:�Q�)o1T%�����ݯ�Ôt�z�	���z�u1t�9�c;�����:��z����j��,��IQ���ɻ5^V�ʃZwr$iM$7u����ӣ�N[��r����'ǋ�q�V��@�g��S�##��9-�cL�A��>�/a�^�iC�u��)q�[z�N����\ђ��w*���d�&�E��6��[����;u'�L.G�G1�w_�K�"r=߫�����}����pF@�B�\�ھ��U��Γ�SID����
��y~P���U##K���Y�PD�S	̮ﺸ�-=(Ck�#�[ͼZ; 41u�Śl����_B�MP����;M��mm1�:'o�x�7���Z`4~�>�������$�rM��_����R��އ�����[l�-<wkx�u����l(�J�W�Ϧ:�޿],���>HV�`�]$H�=�N�'38�FG�3j���j1]wf,{<{&M=�����5�%�.�d+M,�M��{P�10�,o�[�a�GH�����(� >O�+�K�ǌ�ɛA��l���7�H���NC�9��뽱P����uL��3w���Ii��$�������Ϸ��M���G�M.#G����C�7��z�{��f2s-n��NUVc����b�>��8�έͳ�{2.E+F�i<��C����>�%A��d"�7���+�Pᦂ���$���\dkI�놴3HΑ��<�<2�}-���f��l����>�.�)�BP��×���tliϻvq����,��LP���֜��ckw%�X��v_~�Ӿ�����H��FJc�ض���=VwAX�w��p3��b6���^U����!�.���O���C��z������j��װ��X�"���,SleIB�}�����S�Q�J,��x��L?���	��x6k�AN	wcͅ�~��~o|8Wb��ciS���y��2V���,��v��-�.R5#��98�8��u�<�,�ǹoV��x��xx��x��jÃ��L������>[_b�7Poݱ��Vv��U��@{��h�m�]�F�ʇ �� KryO�36�*�X������T�>x%f\1+�1u�C�d[t�����7�ˀ,(2��!8�C�$Ŕ~��S����*�cJ0�E���� ���P�Q��1�p����)��Ǝ�i�P�!��A�ɕde��~�v����˹P�U"��y��u3�1>��!��6������C���ߎdD����/����i+��.h֮��xkT�c�O?������Cl�'����\�/��
�����b���G�[q �����!F�l8�8��a�Q�m�f�� ��h��(��'�{-���9�J,I�L��uWA%Q�w�Y��7�In�#ح�hǇ�y%=M{��������q�g�7�J�[-1 �Or��v9��r6�%T`���i�Ӟ��y���Z�����8�-3��r'	��!��&C;����|��������g�&���*1���֋/�k��8���kSt��7�eOs�/���\%f��r�-��*dU�?eL�ୂ�˺\w��XN�{������"պ;{��\nX��l��K�1���MXfa�AEa1�$����.a��TXG�� ���?�p�WRCZ��n)�(?��>�6g�m�p${З�MX��:%����'.^"��4�w��Rշk_�Y�G��]��k���n�rmDNm�:� �ۙj=�]�9+�"#h�Gݟ�鴍��i��x�o�	B�n�N�Z~�n7p�F3@�N�G�{��%���j,so��LWq,0����O�mp��>1��zw�B�\�6��p׼���+�������j��K�1V���]FL�P��Μ��{}����n{4<��h*8Z$0� 2��5���*���j���oPQ����}�O�7�t�!����ӊt�֟I�x��B���n�>�8c�Z꥗�w|�7� ����gv&-^#@����>o�һaD���G/����9~��͔S~�����~A9�	�Ku�t7����	��ԭ�#�bU&�p����?	��̂�z���+��6weB�/*~q׉r)��+�I�n�ئ��˒��y���.��G�w�y��y7�i
8z�V_��`z~���1��L�"�z+bBGS�~A7�˝����I�y` ZQ�q%����#m������i�X}�%WX�@#��p0�)�X'���%�ۖfa�Jɩ�Z��1Bٶ�8�^;R�Ήf-#K1���q��O��U��������1vD
T���^��R����1���.�׆��QؑJ���\���n4��xe�'��+����KH�f%��^pк��Q�P�+��4������K;�v����3��\�z�fE���ңseaub����-��<�d��sPq���)��I��t堾?z��_������o6��m��?�p<^,9u(|`��z������X��Zb�Lg�"r�L�3��j2Ȧt�r�v�ee�0� �}+��vޅ�\�<x¸�Z=����8H铬��L���;�z���E`�n�P�|��(�bz�X
ڥ�ow�̀�MY%<�oɡ#[|:���r�bq7��n}�$C?t[�u�]p� �)�i��y������ͷW�hK�
1��!�"N/�`m��R�e&����/��P,�E߻�؀�z�ޘ�b��m.!3�Ę9�vS��lRp���)��IxY�
�3,��$]�h��Z�J�X�GK��g��cܻ'�WU^��5�a�6U�����r�Dv�c����E�U�ޛ����KD��8�
:��=�o�S˗�lG��}��1�t����qd*E��g�3�8�@mE!�e�K����%7�nXP�s��|��'~�	�]��,?�����uY�����s>Ge�8~@�f��FZ���$sR�[I|�[������f��p"RM
,��R� �� ��Q׵��lѫ��� d��+�_�N�]�T���~���y0���d~.�Ep�}-BU۳"��o=�0b^��l�]T���_�V'�?e:��d���#�8���^�q�7�(��_�&|�+v�ئ�y�I��X��߅�5�%,Rקs_<5���I���H$�4B�Dc��pp�ʰ�,Kx�������$8;�T���Ļ���~7��Y�z&��$�=��?�^�D�i���8Q�Ǭ�{����#!2�㛥�^�)�Y�r{�[WB�7�NX�:�D�yؘ@��n�ߜ��k�����D�W�ԁ`�ͥ���M�&�=�:�;bD�"�j�Ϝ���ˆ���2��έ���C\d�4]���bmɦ)����S6����p�����S;VX�ԽZ� l��
W���K�͋�pN̘(�4�wed]�q�m̑Dh�AY �ěٿ��e2v�粟�.��nr=�n���
xu����]�����5I��֟���,�HGn�1�����d��;o��^��<\�(8�.I>F��q~���X7U���Ǧ��_�M)��O���Gq�>�u���ޏPĴ�:�v�5*�^+�8(����e�/�b]�g��{�n���0|���!�ł��M$k�ά�6�B�tUM�]ױIV>-[�s�n��v����-�1�ry!�j�<x~�[8fH�UQ��»�N!Y���\D���[IH�,,a7��ɷ��{���Z�9x\�+K^�&� 	�����1�K%��y�#K��ɓ�ĦO�z��8��⌏�Â��[���U�����)�h,.��MQ��{�b����#��ީ�����������������rZ�{�ʧ�[��b��OUw�Q����b	�ת�.��DY�eՖ`�N<�%�x��fʀ�pJ_��5K���y?������*�g��)>'��^��j�o����4a�ޕ�Sēr����Q�w=���#���	�Só�"�C��?���!�'|�epը�뗛�}J�����[S餢4�e����B�5�&,�\L�    ��8��ɷv�)u�n��A��jb/{^�ДN�5��*��#Cl>��-�X}�t�c�3Ӟ]?� ��.�|�!~��k��w9ߟ��;��$���y� H�"���<�;k�����NS�1�#c��p��}��"�c�!4i�{����uQ�Fu�ȈZ@v�E0Բ��=��U�'����O���>�}��2�.5��@^�����D@r1��l�U������Y7ָa(Q������}�^�"�J��[cX�A���?�MQ/ZN'��\��}���V�sG��?�LI�R7Žs�����#�g'���ml�L�
��p��b��-��������(7��[�-���+7�� �&�ȳ����2o�r�����W2����6�?x�h"u_��zZH���e�cWN��s,i�ߍw��@S��"@N+OJql� �G}0�
:�<ÿ;N�o�¤*	l��:�����&r�T� �;�d���Ke��:��H��y�����\r~���տ9�,!�D�0۷����CG��E��e�����oJ�m�L�U<$FnOG2�q����0"��d|S��ոgY�ʗoxf�[��Tz��7,��p�:x%��h�M�������ɻ0GZt(�`��=��;P��H�\7R*�ρ���t;!��h�!��#H#���O�߳_T8�C\'����$���~��K�_|k&��P�L��T>h�;��7}�����E���tS���:~%j�/�i�������=��w�IT�}�ӿ�[����`]�m�q�)21��XI#wϸ�P��?�}O'R���*m@�Zɒ��{(h=s`�ȴ�����_J�#K��A���+�큯Jq)������M���x!��"M]��ϝ��D����U�ֆ�˻�]5�OW����9}=��PA)n{ln���{�}������nΈ�t�����)�]D���]aٝ]Ƭ���i`�Aٺ�׌�x����\�zO�S�d�1������	�e893���1���i�uj�-�����&ݳ[�:Mqӄ�{8�t���	�Q��	��J�dO?�GP9�^�o�!�r'�[��Y�uЂhlL1|E��g�銓z��8>]�r�g"�T�W���Y���V�]�!����]t#=��4���C�����$\��L�L���<H�
��o��l����\u9��9����W&�?NYc�C%-��t0�T��"�)��V|O�X���lYr
�٦Ѝ����0p��%N7�}�v��7���ѿ^-�B$9��s˟V�������ٚ�����88Y@�^�{�kDH���ڰ^�Kjߋ�S��T���c�I����2�(�a�4wP�=��~����H]�rA���G�'-�Q�G�P�ĺ���ɮﴉ��^�ڳ�N	֖)�U4��OQ�s���r4�����(C��)T�'�SH����C7��_���������MZ��q��O�1^��nGO����6�x��'��JS~�nT�N�k��F����([�U�N�YQ�O���������G�o�Y���wn>d�����zs�˹>Ev�Ȍ�J��T@��֎9%�C��jy�1��Q�z禬�T�i���>���˵��O :~��\�n8>����1�Έ|�[���)$l�Xm��L���73�F��[�jK��U�|:~GV/:�I$>2��ƺa%,N�"᎓���?�U�$�J(���(L���Y�_�F�1��^r?��?������&�d��xh�XFy[��b�j-~~��M^�Ǹ2���6��}�����4S�X�k�gD�?�?
z���Y.�+�ӽd��=5?HxMȘ�,�L=�;w��/��yE�O)ϕjj(;6�rY��3�Ļ�T��E{#䄃����C��y[���-v�_��N��*�3�6#�vk>fr�	�2���	���0��Cd�$٦�'����!iIu�ǟ�\e/��?��9v��tO���Ɏ��5��?����1[�u�5���JbS��W��Y���/�}h��Hw��U������m�I4輻o^/�r��pc�D���Zz�=Z��$>q?D�C���G�L�E�s�3Ѵ�����+��9ۤ��"�,��P�l�bR�.*�������^�'����	oov�﫟� ��ۭ����F	� ��'�5�B�:��C�.���p^N���Bl�D~S>���s�ǫl(+�hpCl9D�C�����Aerq�M%�g��\ַH���	�@0�ٴ�Z�\���J�$��0$�}Zk;�� �ݰ2�&5�������>�AmjȜ�{Z �/=h��������s-^st����G��7�uX�b���3ǟ[<���j�{�7,ہ�1�M�i��ؒV�5�/����w���O�����畣El�g�L@8t+a��#��i�]y�������/�u�
97Dp�,)`R���L� ^E#&G�
)�Y7��Gg_h��#�-U��!{�W_fV@r��\/����m/�058Ȳ3�����v�<��7���!AE�vXm��;�YCFks]Err])@I����>tT�v�Oπ�>#qs'D�ԥ:����
�̅AjF[�Cͮ|�&`�<7�9WI���̷��j�`a�-���a/P6uw��Cܟ0Q[�gD�y�_��0��Q{�bg�"�#��S%_]ئwJ��G��և��Tf�CK��x̉�atG��-�~��}�5�Ӳٹf��\t�c�;��/���8���8���I}y..i&�Y���NF��.�		�����Nߔ�ed�3�ż��5���y��T�CD�5_�_�n�n'e��B��(��p�3�bҭLhc�NY����I�hcα�Q<��I��`:��B;�]o�~Ot�����EX�=v-#4������μ=t�>�rn��u<�?��~X'�Q��vf:�	�`?I��R�w���_��ұ��\�g�r�4�C��=o:��Dceq(�q����	�~�����`\���hYE�������j� �ʀ8�$i����bk�
�]R��qY����U�I��@�?.;�����3�4G/ij���[�R~:9t t!�q5��t��հ`�d�M�h�ٸ<vDb\����f���e�O�_��F\�X_KF6��yG�_��8����'7~~�FQ25+�Ƌ �33�í
��� �o��b=6�mt��Ȫo����#k���un�ޚ��fߊ
����9��(zr�(Hd2x"9�~(W�=����F7�cS;��gj��o&X��>w���7mƹ��FbV���|�t���3J�z{�$����Ȇ�g��	.'�7�Ttl]�n4�Y@�Hx��.�S}�����῿�_�	6�.����j��3{���3x7����a�Ӟ�Tw�S��oR(��*�F�h�~���̽������#�ozԻ�U%����@�;u�@�(��G;x�E��&�!ZD��}���}|���q�o�����mx�C���Q���r�Y�>���H�O�o2�c���i�j�����P����պ�z����?�TI��|���J��Y��3WyΟ�k� V2�v�%�m�MT�69jc��X����xL>��vé6ܦ��$�v������l���,Y�΅������1�Ek�.Y�ɚ�|��'���$�1��
�2�];��m��Rs��h�j����[<ߏ��`�:훍�<їm_���X���XN�F9奂�ơ�IT|��U���c���G�9e��c4��4�ڶq��nU�e>�%��6��	�exEw�	��č�Dv��L��w����w���~�T�!��_�Ρ�����a<!M�G��j��"d��U��G����+���]�bԢ�ŷ���)��8��������_N�,��qV9�S��v|����%��0t�	�H�p�u2���i�Y#VЊS���!y#�� ��߅_.��mtWښ�࿓���:����m�Ȩ��6=H���"���U$�7&���B������ѧbJ    _/ �W�1:{!�SEW��#�������;��8����������e���u��(�O�W�\vH��BSFb�7*O�����xP�1�0F)~E���=�D��o�9r��{Q�W�׼���2� u;0d�w��^�� �G햵@#W8R�w�� 9jI�����rZ�k��=FS0+�����{N� }%#�0?��(�$+����X:��v�u��\:f^�.K������P�������>�UE |^E1��4L�\+��g�sL�/�srO��᚟��f�5��(�[Y�cN���\�5cw�F\���^�����ނǍ�8e^^��O(!���R#2K����
Μ�M�NJw4� @g+\��Z�v'�'��� ����w&�]�ͱ�p1����~���AsWlR~�}�
��UW�r���q��8�QC��;��h�W�4���NOu�=Qn�d�J��S$qV�z�j^�ߵ���(��pxXD%�)# $�n
���9�D<�{�k֖ӟx���#v��j�|8�B !q�j++���w�C{w9} =�FNP/��[��G>���A��8�v���	������|��&�l��k|�������pǕ�l ;�)�┡��|2��K޼I����d����e��1�:/=h2��)��Ã�l�����=�2/!'S��279(�.����3Mh{|V��czy*gO/2Մ˸]����=��W�A�|m�����פ>���֙��5~PS��}�R�������������zqk�w)8���Ê��%�ف8��~y12Ȯ�h3�~��
{�(7���x�ϡ4��b)�!��t���2�!��]������;<þ�B3;53e���8bGv��zՑ�y������Q��>4��eJS{V�+��~�V������@�|8<�gf�~e?��a�u�'�������A�������z�Ma��|��QQ��-�����9	W(��P�{��ş QΎP���V�B���e�E�6����i�a`�v}�1�9u�@��`[x�̼O���4a ?��_߭|��ez�I#������IE02��=^��e��O�M͝��V��n��^V��g��e~d&� ��4��F͝���R�>r5�X!��d�J�P��~�^_y��+n�o]�������ަn�� ��
�G����W<7��0dw�KB-QY���L��/ڛ�H�n>��;s���	��\1�Q�7%�?�����&���=�wh<�7J��x��6���/s�,���R��p�6�����������?Q��pA(r1�X�v8��|5ﷃO�N{��=����#����cp�T�oE�?��u���v��	�-�贱,ݠ�)X��a,�������º �]"Y�_�A5�ۇ�ˊf�~T�J-��9��]F�����B��YE�~��3>���t%��O��n��Cz ����#d������u��w��:�b�m������HҚ���±��=����^�a�{_��q3��wa'ޫ������=Z��{�U [�����1M���l;���2yՒ��S�i�����*����
��R���Q�������I�l���K�n '���Y�� ���8R�ܐ���4��+�߾쫌)�
��;[w���]�(ȇ�!�ܨb����6!��0�-�i���t���k�t��v������/��&��<�Κ~�~�m��Grkv!V!�!���i�aG*>[�r��0玽�;�]�_̀�{�}FÉ����ZH"% ��8��\����X�f ���M�Z�jvH�͚l��GB�y�2WR�qO���׋���/ږ���k���*6�R&���:�e4��g�﵁��cG��{!.^�8����#�M�Tv8�N�{�8��o�!�xbsM��	���<��4^в1 ���1l������ y��Oկ��U�ۦs�t�l.3n��T�Q�*e�]#�B�\$��,�s�jFG�0�nF+�y���� �󎘚�5�g?xT+80���e��C�ٯ��YZ��:��#��L7Y������ 1]���s��vx��[���:��+?:�ƭ���6y02�;cԠ��"�׋�k�J���?�!�;�2v������[]Q��x���绣�j
�%5y?K�͊��`���K� �V�(lBz�6�G�{�C�S��?���;�A^��,��S�G;����#[�Z]�Xm�sny��6�Ί����~ƻ�2��OZ�W�5]z�t(Ez�^��3ZB�l���f��fQ�l<�r�C���pLAt[X�I�����΃L*��X���\�#� K���=m���Y�� ~�B�}�=*I���X*������n�~9�0���*��=c��zO�:��k�v^W�S/ep�s��i�q��}��YPj�3�ٕ��L� ��N�����!�Mg��[��B�g����mw�T�F��m]��o�?y�8N~x��Y�-t�@��d+�sj���n5�6�Wµ<�{����{/��9��ŵ�T)d� T;P�O2rwm6��W%:>y��������}����������7\zW��1:d��%蔫*�.��ߔ�{�0����p�]a�FpO�|d��O�W���=��F8lT���=_�"1��� �2V�4��w�IwV��Ѓ�K��p�n�@T��^>�<���<(WA��-��5���Q��I�s�u'���oF �Ȏ��lHG1��f�A-nF� �;L�ϐz������0��s��$h�yG�#;�(�i��lF��Z9M�yw��e�'x�V�	�	��b%�Z,�J4�1&�rc��I|~��kp���˅Hn�bjFE�6_���tU��j��3d�AzR�S���g"=���n{~T�G��7�^��-J���;��q�-�����^9�z1��Y�oYp�u�!r���B�%��㖰�/ey���|�/� ���ї��ҵL�O+XOSa�����:���~���wM5��em{e�H=�/>#�+:$t����{o����p����Fq��"�ڜ��=��w�[}�s�����)=�[VT\UX٧إ���5��E����_��կ��?h�3$�E��L.#g�UA���rC���2����]� ���Үd�U$ˮ=�"��h{BL�*b�$!�7 F1�����2��#����d�:�;w>���y�"��`���@�d�5OY���*����{|9a��F28+J���wo���E괤�g�ޫ����C��@\e�7i\�l�rf�S�3�i��\
�+��e"8��Ѳ�V���G�4;G�y;M�}���L��B�b�[����^������(8+*ӾԢXK���"ܒn���]���tӂ�7j/~w�AշY�ʰV�]��Ґ.�����w����߼Z�᦬�Y�űP�����u�MoS�����/��=7u�0�#St~p�ζz���[GM0����1��%�`z��׸����ҡC� ΆL��N�p,>iF��tBYd&Y>�:x�U���ZhŰ���3/4ێ�M3�`���d��[0�L>�u�7\��May�3O���I0�:t��lw'�J}E�bRe�­�_Y�u$vo�	X}��4�����`����<��C;ߘ�@k����#����ɛ�����g�]7��0g;� ���s�v1$k��}�{M�E'�Xl�,0[>T�Ƨeb5p�Ճ��������=��A?��!Ƶ�p�4I<M:F*R*Q��9+2��&5L��xmo�w�Ҭ/tqq�~L��7�0�-kV�\n+'�F��H����^P�h�!�v����lҨU㠠N;�%t��T"�����������O�P� p����7/�M�\��?HT}��7������GU[GA�P�L�GXZ|a4_y�׮l���,,��@���nA�����Y�R8�f�*�π������q��^*z�fH���w�*M�M[>&>�|� �PPp�������ǋ�g�.�����7��ԫ��V���s�媨�T�go���u�Z菰۟G>���Y&� `  V{-|ăމ���f�׶���3��' {�^��5U��wO[���}Q���xK�Jߺ?���
��Y���׃/S�<�bs��j���V[{�f/ϛ"5R\&N ���� ���3�roc���wb�ŋY�7���'���S�����g\2�!<�Z�C�#����WX���g�1��<��}���X��B��d�eq8�&m�"g���w��n,Y����8�zb�o?�ގbu;t�yלU�/��O�-�؈�q�Y��w
�,t2��<�϶e|E=<�����|Z�X�	k�(�F�;���5r�֬�P�߸:E&i�ôv��J���S�ߙMk�������mѦ<���:�TR�~���n���v�i9⥳�R]��X���aPz:\q	(�~@6,���5Y�T�At7-Fӈ��4c]���v�Î��8�W{TY�c�`�ppg�3l�48'�9�Ξ�Wo�Z�N��~
�/&�?D�����i���K�7T�nų����ӎ�k4i*�M�;>��="a�Ca�jQ&{0�s8b��Ю�m���H��O��o)��S�bK��6���R"i��&���<_��[���q�.]
�6�g:�~��F��{�6�)�2�r$�t����ks��������9vh��l�+�����29SX�Ï�V�%-6��%�%9f��p�:�7o���&�ӌky����.��r����t��mD��b���!��Ր:�ě^�x��}��揅�kuk�f��ԛo��cY���͢�5h��Z �D|��Wc�[��@���u�+�{�H�t�62�.}ח_�~��_��&xQJ��� v��'�p�OG�}�Lo���Hw�1|69[(��FA�o�|n��aˉe��S_�w�h�͕N��%�)K#l@'����R��0Ñ��ߊ��b�G�����Rj'��;E��.򜟩:��E��6����<˶[X����%��o]8<v�z[�6B�S\�U����b�ҽ䫣2�Þ��׮P�g��68U�.���	X~���,�����}��=]�mW88{���	;�R��^#U�4ʞ�����'f�����Mp��w�,��x��
���˸ZJ�7��R܂�kX�4$��
$��g)�aI�+�Ɔͳ~�E��P!�g�CP5��iVk�.�w��Q�+�[6�^�����*� Ti݊�!����a���YN��Gh�h�E<���VW1BĤG�s����k�wtw/��u���/�mO2�����+y-�嶂}�>�vI��;�t����H��].��n�؈+�hc���U-o�� |�v�ݝ±��gF�i�N�Zn��ӏ���i�Iͥ�׹<B�G�慄Y-��a��^�	)Rf<x��đ}��x���bٻ'���f�4�κz��<�oz���rn���þ��_xQ�Q�#zi���E�QJ�~���z}?��-/?����;# %��\��E��~�i %ހ퇉���9k�*�nvPܘ4�_D�nU�!i�I�۝s����R��b��uIC)B��������xcl�����ةF�]�!�=
�t}4;����7��\��m��$����?%����7��'�ʗ��$�u�X�yh<@lm��ݮ<=@~���ےTGT\
���}0����_�e_Ǉ ̪<�oҒ� c=E�+=H���@Od�~ۀ^�XNiF��L�|��G��ٖ�\z�}=��ѻ%��ʄ�HxV*ߢf���e��]h�ݽ���Mܼ�R�)x��I��C���+>k���rl1�V�s�mx����pM<q�1�N�o����/�)�ޝ�/:�o6y��MW���7]|tš��ݎۦڿ�Щ>���ڜ���ˁ�#�2��7V���ƩԊ��GA�����dg�!m�Њi7"�?I�����Ec����n������8@>S{�Kt`�'�T+Y�����ylL�%�G�H�D#᪕�ݰ���a�M�~X�P��B�	��v������LR��֡�}P���Fʊ��Tld��� ���y���!�����WTD��zB@(r,2�:�Q�$�ݔ'��&奈,��{,쁪��P�����G�?�
�%���%l�~�9o�YE��@�>�7��cycbHճ���pp/��_.��n[ފ�j��R���TK50&�����/��80�y[	W�uo�Q�%��b*�(A��Qx�������>Hy�ĝƪ�]�o�D���&ōq�Í���{.d��<�#d����;�����"�)�^ "�Ji��~.ہ��tԊ� :��ݓ<y�����FS�8J@���u�B4�KG�Q	zv�9��E>L����d3�$��d�O7�A�V�y�Ӡ��M�fu%���O����l�a���g���y�fO�m�Ϩ�!���'��h���ݘ�pB�$��e
��������Hv7!�>C���¿����q�g�cy�u g�&�e���v=����|	�+���O��M#����P�Ʊ����a&G(+,��1�ߐf�����Ωy��`oi;�6�un���Ҫ�耱n`���(n0'y�`Wc��6q�W�靪��0S���s��T�5"9\��-��i����}�}���լ�k����ڂ�я�#ʇ�Y��=��U�������.1��h�ӹ:�-�vض�Q���G�'/5�(��sTꢽD=�w{�V�
ԢQ�.0�p�oV�M�椝rC��!!�9�e�P�c1lX����4��S�~��ڳ��pN��]P��<���<�)��ԲX�;\{j8�-ì�I��ϓ�����`D�?���;ˣ�������	Rw�����E6�����r��J�:�&�t���f<K�t�*�7�J�|T�Q�ɺ�TP�@w5�SꌱZ���_�.���f��nh�S3�$�
�����u�z�U&����,g��}!���n�I�7[�ï�+��^&�O�_�޴�M^3,�e, ���'�e?	3;5r=��y�����B�΁�z��i��鳰�xϢ̰�&�[|&���T�;�y�7E�h�'Ό�� ۜ6<r���1��F"�è/���D C����8a��q�v�5ȟ�̺�DD˒�U4��������Ա��7��&�✳�����m$�h����&�ͅ� ���-F9~� ں�Ndf�uM¸^�7cm��p��}T%���t��KVy��[��t�䪹�,�Bc��Esu�1��o�>���M�촵�Ku�bk��2�lT�&�x���[�C0�qg�D2~R��_DG��E2�OB����Ztim\1cʵ��Y�T���z�>0U�p�n�%%K�m8�����vk�ݓs���WAI�m��y��љ������^����G��]���}/�rs�
���>4TӞ�3�-�-�`O�Aqk�o��mE�������#�`���'J<d-��p�լS�G���.��Qf@�?L9�⹼�XL�l�r)x�W�cmׯ��[U �	� 	C���=�'�����ve"L+9��x������fV����`���?�ݟ��B#�����h���l� tf�Z�}}����n<��iQ�p��/��)�R�D�R@�$s|���\o�?�'������b�?���C&<�Kx�J"�@��N6��+�A^�.����;d��p���x�ߚ�
�F5�O
��t�ӓf������������
N���?8��_U�������?>g*�P�+�7�c4�DHn�u��κ�_�iR����m^����z|�čW'�}n�/?x�`��*��5��Ѡd�6�S������Jx/�^��=����KX)CF�y5����Tѐ�DT �1�;R�G%�;����2��}Y_�?��?�W���9J������w��߿�����m�      @      x��}Wӫ���5��r�U�� ��;D
 �@��2�(2��ߠ,��=~��>�F^=L���	&�G'�T��q�EĀ�5����qb�f�t�N�:��b�v��v��n��uп�b�$����le�t=A���j��dc�W0]׌"ql����w:l�7���?3bHG�]����#W�ҷ��{��w�����
'C���ߠ��HU�Z$��&p=DtZ�ѥ�/"H�|�a�e��a�#]���#�E����	����,̖�r@��+�{hM� �PtG~@	��ѕg�������D@�Q|-_%�ً�}���i" ��4nM}��]B��O��d<y{:�g���q�z\�C�ڮ,KO�Y��7K�ι�u9ѣ79o��1��Y�@���x��{�>����a�s:)�+u�Ep�����.�۳]k��J�煔|ɴ��B��QҢ�ز����{}́8�v�6�$F�Sbhe?�[D��!���.��刄CǸG�s` N]��{��&���Av��<�3�$`��{��'�hw��7L!��c�p ���JD�#�P�7FN�|�o?�&����Y:�]���=\@p5�3�!ۋ[c�&�	��q1��66�6�c��� �������h��D�B �aԞ��,
pF�� .�z������~�.�`����!�a�rk��I�v������H���ē	#�j���o�P��iauck�E�!fv�D��vjD�M�Xo���x�
Ծ��k�^�	���3yb{<+��@G��]M����B�X�T\�Ti��X�ub'��
�����B�1��M���p�4<I�KϬ���q��ՙ+���IE��1�9�t?�8|��y\$:6�0P��6�]ۻW|-W��%&�, C���>��ƃ��g&��|���&��3�	����Z��袧�h��hU��#�9��(z��8���R1�y���/�&�J1�,�~�Vvւ�T����tX��Tvi��ӓzl����T!��tBڶP&S{����X#
%��7�s?7#:��WJ`�<��r����Y�R�o;�����\g���y�=/�10�=[�엎{�M �A8�)V�wnh9����(�ad��' gk��3�C�sv=p,�bK�[Wy�B�`����di3��X�^刀��r�\v[���?����P��^���	���ˊ-�I�.�߽7�P�te�%�t@+�/?8//׀A	Q��K�D+��qE�'r�I�_�|�p�q@w��JzTD�O��!n����#\G�q����S&��!pH���*�>Z>!(M2���M���rv�qZwt�ir��0��&m�Nj=�)jc��l�m�&��C=JQE��c��-챪���sэo)(b���TG�HE��t�uR�:h�4��@#
7*��h#�Ϝ����PFA��fI����G�~I�#3�QCWj�XO.��G(JΚI�����e�$QP�%083y��~V�r�g�����%T[O�&�|8�����A��D�D&�&�7��	��0�N>c�06���ymڷqF+�=W�N�gI�Au-�k�\��n��r|Z�`�R������¤/J����rr�*8�@�rk���B
WE�n[PG��J�STQa�Wc�%�Ԁ������\���1�"x�ǖ�ʉ���q{�E�!J8��d�$t)��l��g���Ե���ϒ�ws��%��\U����[��x�Q�fJ�ɪ����c�[��
� �)�Pb�>���,Q���OS�B�f��#�Y�I�z��B�j;5��	��������ѐ7F���> �T�+���7�B�ˊ��v5�&6�o��_\�*^�����*D�7��v�^��H�g�M}�	��W�'�U���4@��UK�NM���FΜv8<��V�k���\���G��j��|ςA��&p�4�lU���D��k���<N�A<w΋�[i�Bh��"�Cu���ğ�z �g�\�}/J�����⼚��D�1��2^�Z��{\����f������uԀA	9��o�Ű�Ӟ�����3L�~�	����Dd���t����	2��gx���"�ˣ����A�C�@ƶ�+i��F��pS��g�*c��z ;��57M��z�z�{���u+4�m��?���p��-���[Rgֵ�����"#-����g(RY���5���nEn Q����%GK	�	g�R]��2vS�>,>!8ބ�նX��,�+�]�����9p�#r�u�̽�ȣZY� >����hv�������|ٳ[c��	n�g�|�[uVy���uEc�J�j�,�4�pF,�Q�1/�.{И6��P�0���Rݬa���k��$��B�Y#���IFƑ�kq��5�p63�h���ґ�x[`,Gު6IT�-�}|�:J�@���{z*�Fby���{T.��7��k�@G:�T_����%�!_l.C�-7u-�v|��q�9�K0E��|K����xGk<.Ms� ��WDO�����!J��*�W#>�l|]\�Өl���L����|H���@��5��[�f�y8�y�_���5�#��Z���k��%*$3oF��	?wP��^rk�?�ϻ���Xd�g�u6:��|��t_�k���(q?@��f��\�()�z�ݵ�ш�-���~�����Y�G����(�ϯ8ܤw^�K���]!�) M*�=�l��k)8�%*��S�v���ߩ7U�<�08�44V�hvГ�!"�ag�>�E7���:�����4t���������j�Ӓ�`�Uνl�o��>݀�XsFc���W��J?r7x,�>������۟A%��Qy6�x�(v�|�q{��p+9�|@��̜�*����ZJ�|P����d)�Ya�S��^�ߛ"/oo�-n�J%�pA��)�e�zF�>(zc�n6=�����۵��(\������a�9tIAHŽ&�'(µ�q�p�������ɥ҆'b�>u>t΀FW����S-	7���|�쉭D���ۯ|��N�Z
nN�썙/(Nݥm��Qm.VLe0�95�̄��ЁͰ�~�H#�k���E�� v�9�K:'�|�j=� .R��m�c?2چ�����;�K�z�Q�����lfg����Q�Gc�[��ݻ��\(��4*K\�\g���Å:���z3
7VȒ�)5uwXBF{䪭����P(AK~!�@e:6�&�2�����ø���tN�k�b*��-IU4�Qg_2��i7;=�����̪�;���0(!hI��D��7C��!��n����&�M|�D�}�4V4B�a�j�D�����t������!�����P�\�+c�ݷ��FBH`���3�XOC�st�������쾇�V�&n��<�/4�4:�q0���X Er��� \h��q��9)vP!/[���<�1�X�n����b�A�~}��<�s[ڦr�cg������·
��%���X={I(������������ BjYG��5���,���
$����zTOBQ���q�	�4N|�P��ܰ�x���4(�D�����'��� �<�K�j'<�c>S�2B�i�,CY�X���g��T١<�����<� �Z����c�My�V��~
��t��~�B����l)B��U4C�j���{
n�N��1y�LǧԎ�����ܯ�����OF�ph���h, T��>!(��t��<�mj�� _T���7.PF\���xo��!z%�����s\��3��n�:jh�����y��k���(��I�L;K}�Ĵ��_i�m�J����2�Q͛;���W)�O)�(�$F�B_Q",����\Y���B	ڸ;��$�Q��}@��x���Fn�����R����}�^�[�2�Y�{\�Dz�w���P��iF���ä1����x��-+��Ơ_��7�^��	������X�)�Kc��<��P��rO#!�8�H�(jQr������V~$�Տ�x��B�,����(�    �dE��������pFe���[UH�Y6�����Q�2k�]۰�n��_@ �ђ��}��v�����9p��J�7VM|���'m�Zs��A���46��=�ӭ��#���BW��f3�Zm�?_��0��h�`�� :T�(� �0i�ZErt�j��{��*��:.�e��r�`��&�����-FL�΁���>���~0�=|(��<C�.#�iDoV���W�o��p�Po��
���ы~�
xO ��ݥ{�y��{��*B��c��nRseϬ6�q����mE����'(¾�!(o>����1?ChW.�3=�|-�������tB6�8� :[u��rj)8�j���ٍtF�#@&�jr�u��$�ؤƛ����L�1c���S�:7�G.m{���(P�A�U�o�gz�T�M�n|��`)�M'k�V��}_VxK�iǍ��f�t��+�J���' gg�l&��Dii_Q?ت-������7��*���Ĭ-�WE ��X	p��p{<A�����p[*2���eCk-	�#O�%	�>p����+Ҁ�#�VA3��O�_�'fs07$2��/�����5̬��Q�b)db_�.�\�}á�9to�'�8gK0�Ml�Ļ�ЄA	a)k�Q��"sL�#W��C���G/hD�:�*�/��]���SއB#�(�	���CN��c�zZ�A�8wA�0\pA�>��	�h�XHwΧ���fJ� -�!1tD�ѽ�LW��� U�ڞ�_d�if�YSA�	[2fo����������tM�D7�Eg�L.���-�UK�u���0�Wp6��˫��g�fJ/�͚Z*��-{WQ�V��V���`8SK'�m*��Ђ�˂��6�����7��+&T��HA�r5�qc�����Wyp�Ư�j�7�����7�m�ZM�~ˀ�k'u��{��쁼����{���p�l����ςs��FV��y9ţ����^�R¶�MVl�v �gk� �[]}��D��hV|�M��8}������� �F��C��$���p�^w���X��I�U.�R��򹕝�~2E͸�d�(��bχ�N0�BPF�j;L?�5�sf�����!����dW.k�fJ�n�f��F�=Ȏ�0�������x��83mb�>�Qf�a���5'�o��ܲ����_�
� ����#5�:���"�݀�Ŷw�q�F����A��[������d�ٯ��a��&5[K�Eۑ��W��"�[�b�	�(E�������M�	�]*��l�9�K'�jr]�gn:���V?�S��=��;��=�n�{w�3|1G���^������r���-�{&qF��绒�L��b�sz^Mj�����@q�����4E���_k���2^.-�`�l���8v����B�}�� 7�	���m���SZ��U�\v1�RpƤ��B��C���ݪ�vb7����E��Ta���:̆Ĺ�?��V??(���	�vl�_Z�rqD\�wj��p(a
;3ܙ4���62��#��X���3w�xy�J�Ϸ�"\U}�}姾HhB�F�ǘsR��,�s12�,}�m(��K����D�ӳC���ɳy{L!3ْ��+��p��������d��������� ��)�PA�m�=>�w�׃����7����a8[�1��\� ����g�L�v�
df s�n��)8{�ow�2��Y�a?J���Z[v�� 7֧���㽴� ��!��<O2c6�4����y=��Y�8�sdՒP�΢�z+&L�K<2�M�z�<iGE�.���S��Gf�E����'(W���r�V��F��f�� ��+�_`(Qs\\se�=���C�?�ָ:mt�d���+��^��̇ދ�t˜4�0�ѣ��M��3��Ns��&	�:u;+�X'?k�wD�Χ�z<O�m�Id.}V����B�7�,�"J�f/c�W ��2��=@�7k���sf6:G��{:��{Y�o��C6d@O���1�u�V'�W��P�>��PB�W�(q�H��lM��1!sW����q��T3
�_��1�Q*+�>8#�R_nU�JxOBQl8�^�m�l��rmd����q�=.4r`
'��FW��^7��[�{�)~�kb(�t�V�>2�ܟ��w%�Szg.A����+�d@���s���3�lo�Y���%�� ��>�7H���6�N�p�a�૾�QSy� �->�q~�4_�:��t��A�
�r���K�}ς���5dz3���x����	�;g'i5:��dk-���V��~����6�p�Ϊ��|��E�wf7Ʒ e%���`�wO]�?W|z���ݛ�(� j4�s�H{�x��k��p/��um_3�f��(ͻFD��\IW�X����p�,��8P��ͼ�YD�i��:�I(j�H��r�b�C�?\"��^n�%�\V�\��?�uz�r~D��n�R�A��)��b�IW*O��M������%n�`K�Лm]s,�s��9�)\���Z
.���&�$K9ȱ��ZO�D���Q�
��5�r?� �ܚ�>{�Z��b�y�5���.#�賲zY�������団��Q��0gR�K��L����:��o��=��K@wL�ʌ��Z.��'r�^?��e���_o�.r��I/���A�� ���_[^m��8�N*L�FR��T��T�_6�>�Ȃ�>������I�SFś؟�� ©�����S[b���K�1V������}@pn���|&�C�5Hu��/M(܌�F���lu�J��Q^��4�J��d�TwL�X՝�����_3
��(;cz��r;)�����=D����#��"��flыQNWd@{��� A���B�:J0�h��}KQp��wk#MwHӄ��E�F.�����ziD���������ck�' 7���xun�}��Ij����7no�B�Y��&k�����L���$�'8��zA�V賙3к��<�\;S��<�؊��+&{lD�m@lʯ_����Q�����nqt�f����C#
gU�6[.⹾ǻ0~.�ٿ���k�+��FnO�5���)0������VOBQ�e'Kvm�ǝ
�z=�v��I=E�{������Rߍ��{��������Ѣt0����Å��p�(�u�eɚY{���_�Q��#0����7_�ω�S�']��aMnY9졝��y_`8;a��t��z��AC�f�zJ+����Z�/���s�]��s�i'�߯(�~Cap� �5u˭�m���{tW`d��Ň��C�2�u����8�֢
8��&�Z
��u�[�#��.��R0�������fx#c7o�aS��j�7߂_`(QO�3Z�X�*�p�����oC���M���]`;)]�+}�G89��۬��E:��ŕ�L�ZDU�.��Z�����Y����׫���o�z�S�.��~F�e% ��]���TK�Қ�z��G� �ީnmЄ������=����P� ��l�����L��Ѹ4�������yŠ�dh�<���>�V�����ʱ�G�[`�Yp�B>�����|8�@�]۫�c]~ˀ�]c�$�<b�x6 �����Q׌B	r;�E�U���I��u n�be8��ow���o�.lݗo�o�-��MzT7S��n�&" .��Ūǋ5�p�nr���y���҅���۽�����䓥���Ҝ��1zy�秇k)8�0o��$p1��=�NU�?�;�~����S)ϙ�;3*:׈d�����Y�ž`��|�����傤����9pq�=���r��f�s��{
λw��v;�H���PU��ͦ/�p*%�+�G���(�����FN��ހ�:1K�F�e��~���h�/����@A�&��l��'	��U�d���\�!jc�?�Y�F���}>�Y��d*�w��<�#w�,�خ���Z?�]���-K�������2��~޿̄;*��f��v�����R+�X/[D$����=J��c�I    8墥P��{���rmO��G�u.��6˩f0��C���Ս���o8��"R5Q��#��0D�ab{i�?�=J���Fa�r���,#žJe�Փp�Ǉ�����r��^VmT�E܎�� _�t0��?����	�{�V��;R�6����C���{�}��B2��lV�LW������j�&��=�N�^�Ģp#Bح���0(!!C;�T�
3��]O�_����s��3���u+B�ު�|�{�>�!]���;.F�f8� Q�AҢ���d�����n�d|�S+;�r+���?p����)�����=��ݐ��}�b���*N^�E����3ō ���%v����m����7�?�Ur�
�ϯ8�0#:;&StVk�=4@ ;C6�qp��V�0\u���v�Ì5�6@�`B�n�yQ�_3�V��"<����=�> ����kD�׹p����l2K�#�\Ku�pf����v1��s��I+l����E�����%�F��Å��z�"������������؊�1o����lO�����W�����p�B��q���]�$ݩ��սAQ8S8���1��ƽ�;��{��c	���(N� �lW�a���`��r����O;Y��6&�a/�V�k�ÿ9��̄�..��(��[Q��s�����I8ݠl�|15�=�/�'��(���_`8Oc:�=Md,�(|�	�D~g7�p����u6����*�����Ԧ�,2�R�G���F���?�����ec��piL�aܯ���e��E�g�,:Q�w�� ;�^_�o+
�
hF���-�ztf'�1z���W����j�H�M�]������.-ѲDh�o�b=�6@p���ft��8��\ �lԽA"���fP��鸚5��U�s�{+_��o8�0L[��ņe�ϔٕ�z���3\�kDm,�H�Y�y�����������5�����bK�.����Z�]�p�KX��u:�Uٓԭ��&JH�>u�u����T���續On.<(	�/��Z�w����]L��E=E�s!1�Ŗ8f��e�3Z� ���m;q��'���^ݩsse?�O�e&�?��%N�я���|m�: �P�V�F��a��؂�Uw���]��첛`���*�d�v�K��4�n�'��I��[uU;ƙ�����JTI��Zһ��Gp���·�H�Eߓ�����i�Xoq�٬��	X<�u���e����{Ρ�&���R���E�4�K�y�' EO�b���S/n����q�[ �� �	��c�'u�� ����?(�2�z�m����*����A�� ���V�\��+1���+�q��z��WyPB5Q�m=�Zq��̑���V�����#E.��+��-��B2���sq%�ncF��Uu���΍p�^Z;�'��Ęy��y������/� ��<f��^�.�8�M��_���P�~���Aﬅ.+���F��@	`�|�ѶZ�юq�7��؈�E
ZM�=���W}����>�O���5�Mf�<�':�+u�^W��-f�r%9�R�|���/G��>w�p���M��t�փ��(\L���4Yڛ͊�6�j�Ҁ��Y�:9������:=ߩF�{�@1u�p�6�}t�
Y/�!;�>(�XЬ=�4c�п���7�xrj�"��������^�1Q��Ɋ߻�|O�ٲj�񮮋+B��7���jn��%.�.�O�R�xΈ�����a>~T�,8�]��||Le�j;ݺ�újˮ}ֵ����_����kW�V�X.+���k���p�-���`�m,c�ae�^���[ʾ�pS�b����M�X'�d�����0oD��Î�T{qV�����������*�s�tn������A��eO��lJ-	��q����nBr4��VZ��o@�lR͛d����b��{z�{�ܼ��9P�[����4n���:��]K�)8�~����x�)��^�u��p����������r�
K{osa4���˭�Qp���UHן8���I)�a�� c|	�ݝ�z�tm����펝/�Pt�<��6� �y'&��)9���Jd�Uwۿf� ��=�)F����QS*zۭϪ	�
�ݡ�I�Aa������j��F�_��ͳAj�b����v�8nUg> ������b�]����s;`6�A��Z��W����<(���CS���ݒw���W-��y�||���Gd�T���^�֚@8��ٞ�����1M,�������������͞m�x�E�m�����E�w�W�R�����u(�K�?��P��9�W�Ǟ.̆�]qF��|Q�����f������������[�L2����3ctX)6�yaP�އ���C	�z���������!�j}�CR�J��Œ�x{hņ~g�U�k���'�yw��;�D0�G泔��~pf�����Mb�]�� [�V� nf�����|�L�	��s��'(B�'YJ�v��v| 3y"�Z�\���$���BE�Fm}�In����I݈����W��H��WJ۴���o8��hI{R.B3'6m`a%�a�/��a�
�B��?���V�䌿��/�%�=�9j�,}0�T�Vc�L�V��7�/2��Z��[LDN��
x���\�~K��4�͘�#�æ[�9 ���k\��v�ȁ�>��Ň�)Q����{���ڨ�	(Zڡ�x�������V���W;����$�*%y���x1���Zu�zO@Ѯb�$�EL���� XV�������K�������⫂e��y;��'}׌/�pA��!a�d��I`�TD�=ٮݎp�@�%�������d�L-����S:��4�ٶ7�Ϋ	"���/�p�r'�;���$�5Ru?����Sp&̜EQl;�X�Q@�ĉ�<tPO�Y�.ET�T�6JЀ�';r�B���+9���H�<}<�:���nF�5-��)r�,�R���H��o�	����Iǟ�����AP"Z��`�Y;B8��Gt�^W�0�(&�L���z)����pޯ�x��7�D�U��\���������k��#�Ǩ�ϫA���uw���2���.&,I)]�ʼ}��x)�4
��m ����I.̎�GA�t�+��d_O��k%�)3�7�B�Td.0co�r��e7��!���t�0
j��6�PbF'��g����oc��Cg�����~Ϙ�y�?
��J\m�|u�0>���Y,WZ�6"�X��9?6�p�sƚw=ch0�[zk�z���Iu�mT���[�z�|Bc�^��GZ���f��;�I%@��p7@�EFZV	p.�̟Pt�$�t"we��x�,p�;}A�)U�f�a�s�v��1��=�h�d| pa��M&i��� 'w"qd_���/�|á����8M;�{�l �T�<<��|@p��(���h����,Z)V�Dp>tY����:n���q6٧c]9ު���a�{-6�Pb��t�<,N�F�r{/�t�i(ro=Sl-ȅ���GQEV}?���f�@�䞲U���b���u���j��D�i����������]-�\��[�k�Ȯ�wHi�	]ih�K� �Z�Հ���l鴇��ɫ��u�Ʃs���-E�[�<C�gҶ7@$P� �7���ů�������f��ܴ�q��8�*�%b^���Xl�Y3U������� �nW0�>��~ZP��;�JT}��!�A�8��v�~?;+�1"U>�LW	���h�2f���Xo���ډ��=�o8�t�(�h4ww�S��F��^g�(���)�1K���ud#�^�'�;�p�|Y��i�K�㠴i�|��#�����8^�V�NpdS}u�b@�>BQ�.���d�����O�{O��p�y2�1bڇ(� S˗M0���;���p#�8��1�̰(0�ؑ�X�L��@	��.v2Un�3������g��'�ՙ�n�Pk�<�����΀ӕ�b�	�b�e�N�ʱQ���;5�p3}�C�| �  v7˞; ������+�R��N����L8��DY"p�z����1r1m6��ǯ�P�c�XÈ{K7C��٨��.��=*!���|�,ھ_���fgz����Rw�l#9����z�ca߿����F�a�&��������'Я���s׌��rL!q��	�͐}���|�����q;�0��1g�~2���u#�׹P�}܎M�FT��w%r��w���k|=�ӕG�8�l��t�L[$��N�uk!�ȃ�3l��}�S�OY�Ro�M��:������X\/���-a���h|> .�)��\�H|+���%7��՚��)/	 �&�f~�f�Nk���8�'K�\h�<��bݪJ��B���z��Mţ�����x?��J������S�pI�kFZLA���i����o!E��q";zTr+����j�Օ�<��V���h�K�pA�n�6_rxU����?�ӄ�LO��9r9|1m��N�.���-^�r┛�����V�X�?���ΰ�����X������P�1>eX�>]�j߃V¹ُv�4�o�wr�C�4��W
�\ٺ��"�z�����I�$���߆=��
3s�T��z)	�ڃ?�����5@��:y��n��V����%����jq���G�G�Z²]���,�X�3��EO��m��k�xA����K��@�&�R���(�!�ME�O��֚�֚Y�|՚Ē���G� �R��>t~�m�7����ư�`��m��KUoUw
�f�e��ggt��2d͐c�J=���o����0���
�~(�k�qA�}�<�ܹTNu��Vc��۝��#R�S�t4�^�HG������x
z�-�1Pk�a�o�o?�Uf�������v��K�M�렃ñ}o�n�^b�7���=�����pr.�[x�?K������������\H9      A   �  x���ْ�������p��^�(�(��((h�U] �2��t�;������I���I�)Q��5<c�i��!tw�Ȍ!/��[dB�,a4�>��9w���ҙ�f
aF|#�7���#�NB�З�n6�ry�nd���R����v\������!p4�{�x7"�FO`�y��ȕig��b���O��{V���xf�^�1�XΞ�4�~P��5,��΋CFzX��r�t��	~�ِR��(ǻ�� fZ�FJt{Hɔ��?�YW����5���'�|�p��H��N\�h��_.���Μ���0�O�^����n���M��;�##�O��i迦s3E4y<?N*Y��.od�do���{��#gZ)<���&�b�厕�L�_p�v'%��W+K@��<����Fp��H�G���4�?�{O⋳_#��g����!TA�Fw�=��]r��4�I���7�4��h��j�[�����r���u�����o�׵��'�Mˌ�`o��_%�Dđ������S���>�q/�M;��Q*�;H�����eβC<�n�`�]X�YEh���D%{(�#𜙚I����v��a��P�������A�>�/��!�j���J��e�ٖL�g��J��6Y2}���R�	}N4�0��_�(�����̢�i�+<,����R)��ɝ2�;�woț��A|;����~�H���� �6/~Z��*��I��&>���
��_���b�*V�M��dqgEa SQ3���@ҵ05IZf8�l���0�ک�*5"�ȥ9c���������;43�n�5�prk�J��w�X�v,Z��Ɣ�Q�ф�0��jj��0#�����?�<l�cU~��ד��X�#nc���ʭک5�%y4�&��nh6R�E;��	���xA%�p�	:riz��Ѩ��xM'v�`�u�0F���5�978B� �)Ċ���,�X���41�� ��Yӈ��P�w�PT���7���ʢ[S	�щ>�	^1��ݻ�~�������"����8�ĕҩШ���vhM)�Rxl.�w����yzV�����Z������^BbI��$�f")u�'6O��yQȃ�(�n����jk)�*ѽ��>8���_���K]��B�T�V�h�"�)܌8Z��t�W�X�����ףZ�˿��l��~��;tz�<���9�u��K|�V��C�npR���*����dc�:�4VH����Ђ�=e�Zi�	�{��Ĕ<R�m�ݫ�Y�kIRi���+�f5���!��#1|ag�qǿ�Vt�A����]��'�;v��~va���hPS8��*X��w�ӻ ^KSX/�_�Vxm���ᢛ	>Ӓ�){����s�<� ��td����t�D�/24�v6��\�O���7� y2��w�����[����VA���"\���m�^"�O+�����i�G�pS�}}D�R�{�[x��%
}��?��!�F��6ɓ�)�y���2sð�D4?y��W�ъӷ�a�3vQE�����m���[�d��ҟ���w>'Z�&�Kd���܆`�9M�w�'^D��}MRoH�0���	8���#c���]MA8T�C�3�i~����Y��hG�����n����I�N�SlF.��dcX�1�	ϠXl�6�oT���D��ktį�5?2<,L���
��p/o�V�������-���4x���,<@@az����#CM�˛.l��+
��9���V|-&���f��`�[�V�[�j�]�v�Xc�
������y���9o�V5o��d5�b��K�U����|�5�4���)�3;�6��b���Vx�G���E�o-�;����O�^�iU�j�_� vo���aM��f���}���k3[��������Ƽ��BXľ�g+��U������ͱ������#\x�A��k��j*pg�0���#�f+8Kk�|��kj�ė�,�3m~�&���:�����hE�@������3s��W���)�v>/>mH��廣I�u��L1�2�H�M�0K_�Vtm�S�Ǿf+��:=��<_@�Q�d���,�TҞ��]��\��\D���_�V	��M����)bc�D��H .11���ʯm�q�e�#�h�Px�un�9��9�hC:�Vl�Ũ谚Z;Z�ĝL�3�h���I��)zEgKA�0�]A#󒚯G+��-��j#�ū͑q�2������ʫ��Jّ��,M��q6mҾO�z%)����t:mY��ܚ����p1lu��m䢿�h�R��x���VxMI�ǝ�OkuehbUw��ܐ*�V5-%���t��6���}}	�,�y�c+�V5E١ΎH�Q������9k���Z�մ�iE+��6�A{V^�T����V�5�Һ��Pi&J�Ps__w�h7���q���H~�G>n��8�H]Q�->xר2o�˜��;_z�Fhy�5r��K�)�)�6�������f���	O>��bMG��hxޚ�Rx�<��A��H�.(_X
$�VQ�C��3��2��:)ʽ��%E��t.D�@zC��N�}H��	�|#�GbB���ޡ�l��[E�ʕ�������X������ dS�_'�h�\���+&��O�>_Y��zÎ����`_�{>
"�w�4u7����_��^-$�0G�j��s��,�d�R&�p�'8�藭�g7quτ����h,F�	#�MZ
۝N8,/��͒�g��~���"�H�k2 ��ːҴ���5A������Nn�����f8�L=Y_�\��]��l�د���h~}����J*t��ah�6�?��M�ѠC-9�t_g�)�۽ZP>������)���p%�Ⱥ;�KU�����8(�n?Eg#��͓�<���9w'Tg�j-���+�*�I������T�Ͻ�`���;:c��Ƿ��"��&�Q�_��Vq8��8�R�q6�o��UW6L� ����}Kęc;��º�o����.6���-ӏ�	��2�Ly��-���[)r�4�#����0��2��w�|ҟO����D�{4���i���U9$��mY|�=��8_��mr
Qe��r�B�H�M���00��e��0�pk�����D����5TƖ��L�5]7� �̡��@%s�R,��B��Dj"�wF��g����Ty���W�gå�&3@0��Λ�1�D�/O�14�fq�M�/p�y���;��Cc�*M���$���2_�hg�'�c�c%��c���F�{@����.wip�������r�U?��^���p!+��5.+ǋ(	B}���^���j�}���o���r�g+�\|a�������o������#���hN%���\X�~Ww�H����G��䉇�̚Q��b%�c]��ȣ�,_�݌�d��~(��f�]�h���4�;����$]�c��`>#���^�jp��kՖ;������,�$��ى��,�U'�B�<�_s�[e*Ok���a��\�-F���i�O+�ֽiw�}�Hw������#�a|r:��R��<�#b��T���� �<�mGlx9�]js���˿مw�{�*���O˩4
����>'�Y����B�,�0�X��"-��-V�*�H왓��߯���b��      ^      x������ � �      `      x������ � �      a      x������ � �      b   <  x�m�Mo�@���+�^5����Im�F�ڤ%�2v+�~}�M��6�f�Ó	#g����ٙ��-���L0:ꪁeLF��T� �`wT��pWbV"]�L��(�g�G�1=2.t����
UwRR�H.L�vI�U^���S��l�\�3ϔ���Gv9�U�_���5��l��vw6�WiO���L�گ�긮c�q�Y���o�[�	���a���}b��?����4�g�H��]�A�b� @�t�MM��c����dg�s�0\���P���|�^֣�� �_H�����_��E-˳��f`���      c      x������ � �      d      x������ � �      e      x������ � �      f      x������ � �      g      x������ � �      h      x������ � �      i      x������ � �      B   �   x����j�@���)��̘�սC��X��/F�4 Fk�5O_#J��000����|c<Z�G6'ІK���Z@/(��U �b|�ہ����a^�����շ�s���s�Y�ފu�P�h���"}f.�0�i���V5SܖA���{�_���o��UE�9���,�~����M��E��Q�B�(o���y'���=�un�c��I65��v�v�&��      j      x������ � �      k      x������ � �      m      x������ � �      n      x������ � �      o      x������ � �      p      x������ � �      q      x������ � �      r      x������ � �      s   �   x����N�0��O�� NO�n�PG�!�7.^��Oo7�B���i/��|���]V|��5S� �c�հ�<*s�.˴(j �`�j��W:T����Ԁ����F�}R�/���fR�&����I��!��z�#/�Rc ໕�.���$�y�RY���8e�78�l�Xe��ӷ��fV�����Qh�/��&�2���"je;����/NS��&�>&�V��#h�Q��H�,�qO#���;f�      t      x������ � �      u      x������ � �      w      x������ � �      x      x������ � �      y      x������ � �      z      x������ � �      |      x������ � �      }      x������ � �      ~      x������ � �            x������ � �      �      x������ � �      �      x������ � �      C   3  x�͓˒�H@��W�֊yiD/D@�R�g������21�>X=��kf3�!�A�L�f�9y+�o�8{Y[;
贌`�#4n�e���}�I�$��U��������d�-@(,�D|�p�B�;	�w�}q��@MVu�*��=Y����qZ�5z����)��K��m�|Y������
2]�U~qY��� s A��bhG�c�%h��l�L\�(�<�zk%`��-�6keQ�Uz��0�0�)�c�L1{�C74M�b�.�����}��h7�Jh��4�4����f8N00I�f��ƺ$�g��pzI�K�<�|���=��V*JXWK�  �����a��(j��K�0������^��^a��<��E�*���@n�A�^'���Փ4U�n��6��FL���À�γ�ݿJ{𫘛��:'L���BQ��� v%E���`S�����RL�E��~]04;#ȿ�#�=�|�&0�R�G��w'�E)��^M��w�O�lפ��<�y�}vp�$��q2�!۠Sف���'�9�w��&f�q�:7�Q�''��FR�W�.�Wb�n?4\�;U�kU`u�5��Ǧ�9,���J�+�鳨O�b������2n�b����Е��Thzd6? �����&{�7���//����Aq+�V�ެ������'���u5<!�2�&�׶y�o��$�/��;�;�c��U\*�|1�� p����Ք`�̐"�Uߡ�?����J���̡9���{{�B?) ��?'�p���$��x�?0�;YvD���]�X�?2���B.��)����d2�l�¹      D   i  x���[��H����3��]u� P���@�ضZ~���L2'�t�%!!����6{-v鱈(ݪ�4�t�4*��8����p@h��4G�햢 L����_�5��i�� �-� D��r�z���}�Zn�p�<���5=ڛ��M����	%>��%�4�8'��>�!N��fϑw�+�2)���Gq�F�|�1�.��켪<eX�#_���+C݊��u�Z�'
�%nN��h�G$祁x�w� �G~an��(Ư�d|1�AM��&PS��:f	�a��O?����;-	R[Z���3ׅp�WdT�4�c��//���BT����ﰉzѼ�}V]Wٍtް����,�K�H��yͧn��V�����JE7�,˭Է��̛�օ�����]n]+ѭ���?R�V{���e8�K#��oY�
�~��4NN��]7چy}�M�ҭ��	�21&Y
����]�k�)�SɏC�2&I��6g�]�kb�)��~�-����H,-�
^[RA�N.��#�k���W��G���=��)�G�q����v1R�.�:J���E
9a�SX��y��:���sĬ�G���l�8e�*M�[�ۉ�?��f�q��,\��j�o(]�����T�Ѥ���2�u�#fm!"r�,-�$D�i�����DK����2�T�$	\�L 2��p������^����l�́�� N}o��NU"ҿ$*�'����¶�Q�~���g��/k��I�(����|o���0NK�;��P�6��}�c���L:�ʑg��f�5��ه�����d�Z4摀D٭i���O��ɳ�F��fJc�jҒ��A?~3�      F   �  x�u�˒�P���+�v].��a��<A�z�SDE@���t2HL�T�=^����X/]!�EG� >�ma/h�d��4ڢ��U�vR��Q�e+�s�"y�pt�6b/wp���N�٥G=��0�P�Z�
�~������8x�a2e���lΒ9b���z���k�C7���A���&N*�X�ҮW~ן�K�=I[�7��Z�HaT�iz�](6'���f���l(qM�
�cb#�g{3e:u��s���Pas�����A|�f��ｃUb��s�,�LT�s�:��Q�����RW?�J0����uK��$ݺA����7�v6�bb�]�Iٵ�~{ڣ���t�E~6./��U�6~��9��m��(9�\W�6�uܿ�V%{���f��u)(c�Fr���2��,Pl�bj���tY|��»�%����W�Z�#�w%���,���m2�|�P�d      �      x������ � �      �      x������ � �      G   �  x���˒�0����a�2ܔ% �(� X���\D�iD�����Y��&�m�W*UI�.��P6�ǉ�;$��5��;���o=`3O��"d�Ə\���M�m�n��M�Xq~� �(�O����x�H�p �(�4����Ԍ�f�6�n�~�R��&�vX�M�=�?�w�;����DY��ąm�w=�^�D�z�
X#�e!O2`eUW��hEJ�l���﹐�0:�l��yΘ�f �������+�m!}��i �([jO=x����j�5 �(+��\�Nc���wހM�G�U�u˫������A�Yv�yi�)p �({�l�IV�6��� l��"�I�+6*�9J��ڈ܌�J���q�6Q��jҳ]�Ʋ��`S�@R�O��y{Ӻ�}�&�n�]��#�G��q�6Q�H�����5_f��l��`^���A�����M�5��˱<�#sM�l���W�����t/Cl��ą6����8e�m 6Q��c6���P�m      �      x������ � �      �      x������ � �      H   �  x���Ks�@�����*���P��f�o�&Z٠vTD0�����Gg(���*��{��
�}��4�qN�k �Rte�� �Ͽ%�� ��*�뵠�i�/�8P��I��:B�ufBqn.�G�︷�?����D�Ȋ��h]�JҎ�j��ι���/���� ��dM��]�o/9✫�/ѵ7��E��Y] I���&O�2"B��칎�3�H	:~������72J����vy���S?XJPX:�=]��-���@����[�+ڇ�c4�/c�D��b���ǈŨr�ZKz�fc5�;��/TD�5"Ũ_{L��&���p\�R�I�R*��?��z��EVM���P��9rGy�-���Z�(��M��j�ʬ�9�B�`�X�\8c�t�`�(�iK����|A�[�t��i�"]��=��ᥞT�H>�ra��`U}m��7��H�H��]��>�Ͷ�O���
<a�HL0���DE�gWi|B�	���A��c�Q��p-,J(��̮XuT�U\�2Q���W���\��z�0Z���ˈQ��R7�Q��F���Q{(k�x��r��¨7�5l�^7>q5��=�r9�W9q��������l��=��^��n�V�nok�9։>���g�T�S�!��q�����{�xF^�z�_ �����+x�1*��F�^�	��^�J�p��Ӊ&�7#����cw��UOi�(���?i��@=��s�bY�L��x�|?O��eMJ3�'�.
�?���D      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �     